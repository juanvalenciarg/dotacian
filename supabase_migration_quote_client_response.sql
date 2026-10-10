-- Migración: el cliente responde la cotización (aprobar, rechazar o pedir cambios)
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: cuando Dotacian guarda los precios y envía la cotización
-- (estado "entregada"), el cliente la ve en Bodega → Mis cotizaciones y puede:
--   aprobar         → estado "aprobada"
--   rechazar        → estado "rechazada"
--   pedir cambios   → vuelve a "en_proceso" con su comentario
-- Gestión de Cotizaciones (admin) ve la respuesta y el comentario.

-- 1. Estados nuevos
alter table company_dot_quote_requests
  drop constraint if exists company_dot_quote_requests_status_check;

alter table company_dot_quote_requests
  add constraint company_dot_quote_requests_status_check
  check (status in ('nueva', 'en_proceso', 'entregada', 'aprobada', 'rechazada'));

-- 2. Respuesta del cliente
alter table company_dot_quote_requests
  add column if not exists client_response text;      -- 'aprobada' | 'rechazada' | 'cambios'

alter table company_dot_quote_requests
  add column if not exists client_comment text;

alter table company_dot_quote_requests
  add column if not exists client_responded_at timestamptz;

-- 3. El admin puede poner cualquiera de los estados
create or replace function admin_set_dot_quote_status(p_id uuid, p_status text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from admin_profile where admin_profile.id = auth.uid()) then
    raise exception 'No autorizado';
  end if;

  if p_status not in ('nueva', 'en_proceso', 'entregada', 'aprobada', 'rechazada') then
    raise exception 'Estado inválido: %', p_status;
  end if;

  update company_dot_quote_requests
  set status = p_status, status_updated_at = now()
  where id = p_id;
end;
$$;

-- 4. El cliente responde una cotización entregada de su empresa
create or replace function client_respond_dot_quote(p_id uuid, p_action text, p_comment text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company uuid;
  v_status text;
  v_new_status text;
begin
  select company_id, status into v_company, v_status
  from company_dot_quote_requests where id = p_id;

  if v_company is null then
    raise exception 'Cotización no encontrada';
  end if;

  if not (
    v_company = auth.uid()
    or v_company in (select company_id from company_user where id = auth.uid())
  ) then
    raise exception 'No autorizado';
  end if;

  if v_status <> 'entregada' then
    raise exception 'Esta cotización no está pendiente de respuesta';
  end if;

  v_new_status := case p_action
    when 'aprobar' then 'aprobada'
    when 'rechazar' then 'rechazada'
    when 'cambios' then 'en_proceso'
  end;

  if v_new_status is null then
    raise exception 'Acción inválida: %', p_action;
  end if;

  if p_action = 'cambios' and coalesce(btrim(p_comment), '') = '' then
    raise exception 'Describe los cambios que necesitas';
  end if;

  update company_dot_quote_requests
  set status = v_new_status,
      status_updated_at = now(),
      client_response = case p_action when 'aprobar' then 'aprobada' when 'rechazar' then 'rechazada' else 'cambios' end,
      client_comment = nullif(btrim(p_comment), ''),
      client_responded_at = now()
  where id = p_id;

  return v_new_status;
end;
$$;

grant execute on function client_respond_dot_quote(uuid, text, text) to authenticated;

-- 5. El listado del panel admin devuelve también la respuesta del cliente
drop function if exists admin_list_dot_quote_requests();

create function admin_list_dot_quote_requests()
returns table (
  id uuid,
  company_id uuid,
  company_name text,
  legal_name text,
  tax_id text,
  dv text,
  country text,
  delivery_address text,
  delivery_state text,
  delivery_contact_1_name text,
  delivery_contact_1_phone text,
  delivery_contact_1_email text,
  prompt_text text,
  target_mode text,
  target_role text,
  target_employee_id uuid,
  target_employee_name text,
  item_name text,
  item_qty int,
  item_size text,
  status text,
  pdf_generated_at timestamptz,
  created_at timestamptz,
  quote_number bigint,
  pricing jsonb,
  priced_at timestamptz,
  client_response text,
  client_comment text,
  client_responded_at timestamptz
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
      q.id, q.company_id,
      cp.company_name::text, cp.legal_name::text, cp.tax_id::text, cp.dv::text, cp.country::text,
      cp.delivery_address::text, cp.delivery_state::text,
      cp.delivery_contact_1_name::text, cp.delivery_contact_1_phone::text, cp.delivery_contact_1_email::text,
      q.prompt_text, q.target_mode, q.target_role, q.target_employee_id, q.target_employee_name,
      q.item_name, q.item_qty, q.item_size, q.status, q.pdf_generated_at, q.created_at,
      q.quote_number, q.pricing, q.priced_at,
      q.client_response, q.client_comment, q.client_responded_at
    from company_dot_quote_requests q
    left join company_profile cp on cp.id = q.company_id
    order by q.created_at desc;
end;
$$;

grant execute on function admin_list_dot_quote_requests() to authenticated;
