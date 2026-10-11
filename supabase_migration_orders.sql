-- Migración: pedidos (se crean al aprobarse una cotización)
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: cuando el cliente aprueba una cotización (company_dot_quote_requests
-- pasa a "aprobada") se crea un pedido. El cliente sigue su avance en
-- /app/pedidos con una barra de estado y Dotacian lo actualiza en
-- admin.pedidos.html (Gestión de Pedidos).
--
-- Etapas:
--   confirmado  → pedido confirmado
--   muestras    → muestras en aprobación (solo si la cotización pidió muestras)
--   produccion  → en producción
--   calidad     → control de calidad
--   despachado  → despachado / en camino
--   entregado   → entregado
--   cancelado   → cancelado (solo admin)

-- 1. Tabla
create sequence if not exists company_orders_number_seq;

create table if not exists company_orders (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null,
  quote_id uuid not null unique references company_dot_quote_requests(id) on delete restrict,
  order_number bigint not null unique default nextval('company_orders_number_seq'),
  stage text not null default 'confirmado'
    check (stage in ('confirmado', 'muestras', 'produccion', 'calidad', 'despachado', 'entregado', 'cancelado')),
  -- [{ "stage": "produccion", "at": "2026-10-11T...", "note": "..." }, ...]
  history jsonb not null default '[]'::jsonb,
  estimated_delivery date,
  last_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter sequence company_orders_number_seq owned by company_orders.order_number;

create index if not exists company_orders_company_idx on company_orders (company_id, created_at desc);

-- 2. RLS: la empresa solo lee sus pedidos; los cambios los hace el admin vía RPC.
alter table company_orders enable row level security;

drop policy if exists "company_orders_select" on company_orders;
create policy "company_orders_select" on company_orders
  for select using (
    company_id = auth.uid()
    or company_id in (select company_id from company_user where id = auth.uid())
  );

-- 3. Al aprobarse una cotización se crea su pedido
create or replace function create_order_for_approved_quote()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'aprobada' and (old.status is distinct from 'aprobada') then
    insert into company_orders (company_id, quote_id, stage, history)
    values (
      new.company_id, new.id, 'confirmado',
      jsonb_build_array(jsonb_build_object('stage', 'confirmado', 'at', now(), 'note', 'Cotización aprobada por el cliente'))
    )
    on conflict (quote_id) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists company_dot_quote_requests_create_order on company_dot_quote_requests;
create trigger company_dot_quote_requests_create_order
  after update of status on company_dot_quote_requests
  for each row execute function create_order_for_approved_quote();

-- Cotizaciones ya aprobadas antes de esta migración
insert into company_orders (company_id, quote_id, stage, history, created_at)
select q.company_id, q.id, 'confirmado',
       jsonb_build_array(jsonb_build_object('stage', 'confirmado', 'at', coalesce(q.client_responded_at, now()), 'note', 'Cotización aprobada por el cliente')),
       coalesce(q.client_responded_at, now())
from company_dot_quote_requests q
where q.status = 'aprobada'
order by coalesce(q.client_responded_at, q.created_at)
on conflict (quote_id) do nothing;

-- 4. Panel admin: listar pedidos con los datos de la empresa y la cotización
create or replace function admin_list_orders()
returns table (
  id uuid,
  company_id uuid,
  company_name text,
  quote_id uuid,
  quote_number bigint,
  prompt_text text,
  pricing jsonb,
  target_mode text,
  target_role text,
  target_employee_name text,
  order_number bigint,
  stage text,
  history jsonb,
  estimated_delivery date,
  last_note text,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from admin_profile where admin_profile.id = auth.uid()) then
    raise exception 'No autorizado';
  end if;

  return query
    select
      o.id, o.company_id, cp.company_name::text,
      o.quote_id, q.quote_number, q.prompt_text, q.pricing,
      q.target_mode, q.target_role, q.target_employee_name,
      o.order_number, o.stage, o.history, o.estimated_delivery, o.last_note,
      o.created_at, o.updated_at
    from company_orders o
    join company_dot_quote_requests q on q.id = o.quote_id
    left join company_profile cp on cp.id = o.company_id
    order by o.created_at desc;
end;
$$;

grant execute on function admin_list_orders() to authenticated;

-- 5. Panel admin: cambiar etapa, nota para el cliente y fecha estimada
create or replace function admin_update_order(p_id uuid, p_stage text, p_note text, p_estimated_delivery date)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_stage text;
begin
  if not exists (select 1 from admin_profile where admin_profile.id = auth.uid()) then
    raise exception 'No autorizado';
  end if;

  if p_stage not in ('confirmado', 'muestras', 'produccion', 'calidad', 'despachado', 'entregado', 'cancelado') then
    raise exception 'Etapa inválida: %', p_stage;
  end if;

  select stage into v_stage from company_orders where id = p_id;
  if v_stage is null then
    raise exception 'Pedido no encontrado';
  end if;

  update company_orders
  set stage = p_stage,
      estimated_delivery = p_estimated_delivery,
      last_note = coalesce(nullif(btrim(p_note), ''), last_note),
      -- Se agrega al historial si cambió la etapa o si hay una nota nueva.
      history = case
        when p_stage <> v_stage or coalesce(btrim(p_note), '') <> ''
          then history || jsonb_build_array(jsonb_build_object('stage', p_stage, 'at', now(), 'note', nullif(btrim(p_note), '')))
        else history
      end,
      updated_at = now()
  where id = p_id;
end;
$$;

grant execute on function admin_update_order(uuid, text, text, date) to authenticated;
