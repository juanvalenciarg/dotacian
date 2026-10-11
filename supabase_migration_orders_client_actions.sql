-- Migración: el cliente actualiza su pedido en los momentos que le tocan
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
-- Requiere supabase_migration_orders.sql.
--
-- Contexto: en /app/pedidos el cliente puede:
--   aprobar_muestras    (etapa muestras)            → pasa a produccion
--   cambios_muestras    (etapa muestras, comentario) → sigue en muestras
--   confirmar_recibido  (etapa despachado)          → pasa a entregado
--   reportar_problema   (despachado o entregado, comentario)
-- Los comentarios quedan como aviso (client_alert) en Gestión de Pedidos
-- (admin.pedidos.html) hasta que el admin vuelve a guardar el pedido.
-- Las entradas del historial hechas por el cliente llevan "by": "cliente".

-- 1. Aviso del cliente para el admin
alter table company_orders add column if not exists client_alert text;
alter table company_orders add column if not exists client_alert_at timestamptz;

-- 2. Acciones del cliente
create or replace function client_order_action(p_id uuid, p_action text, p_comment text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company uuid;
  v_stage text;
  v_comment text := nullif(btrim(p_comment), '');
  v_new_stage text;
  v_note text;
  v_alert text;
begin
  select company_id, stage into v_company, v_stage from company_orders where id = p_id;

  if v_company is null then
    raise exception 'Pedido no encontrado';
  end if;

  if not (
    v_company = auth.uid()
    or v_company in (select company_id from company_user where id = auth.uid())
  ) then
    raise exception 'No autorizado';
  end if;

  if p_action = 'aprobar_muestras' then
    if v_stage <> 'muestras' then raise exception 'El pedido no está en la etapa de muestras'; end if;
    v_new_stage := 'produccion';
    v_note := 'El cliente aprobó las muestras' || coalesce(': ' || v_comment, '');
    v_alert := v_note;
  elsif p_action = 'cambios_muestras' then
    if v_stage <> 'muestras' then raise exception 'El pedido no está en la etapa de muestras'; end if;
    if v_comment is null then raise exception 'Describe los cambios que necesitas en las muestras'; end if;
    v_new_stage := 'muestras';
    v_note := 'El cliente pidió cambios en las muestras: ' || v_comment;
    v_alert := v_note;
  elsif p_action = 'confirmar_recibido' then
    if v_stage <> 'despachado' then raise exception 'El pedido no está despachado'; end if;
    v_new_stage := 'entregado';
    v_note := 'El cliente confirmó que recibió el pedido' || coalesce(': ' || v_comment, '');
    v_alert := null;
  elsif p_action = 'reportar_problema' then
    if v_stage not in ('despachado', 'entregado') then raise exception 'Solo se puede reportar un problema con la entrega'; end if;
    if v_comment is null then raise exception 'Describe el problema'; end if;
    v_new_stage := v_stage;
    v_note := 'El cliente reportó un problema: ' || v_comment;
    v_alert := v_note;
  else
    raise exception 'Acción inválida: %', p_action;
  end if;

  update company_orders
  set stage = v_new_stage,
      history = history || jsonb_build_array(jsonb_build_object('stage', v_new_stage, 'at', now(), 'note', v_note, 'by', 'cliente')),
      client_alert = coalesce(v_alert, client_alert),
      client_alert_at = case when v_alert is not null then now() else client_alert_at end,
      updated_at = now()
  where id = p_id;

  return v_new_stage;
end;
$$;

grant execute on function client_order_action(uuid, text, text) to authenticated;

-- 3. Al guardar el pedido en el admin, el aviso del cliente queda atendido
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
      history = case
        when p_stage <> v_stage or coalesce(btrim(p_note), '') <> ''
          then history || jsonb_build_array(jsonb_build_object('stage', p_stage, 'at', now(), 'note', nullif(btrim(p_note), '')))
        else history
      end,
      client_alert = null,
      client_alert_at = null,
      updated_at = now()
  where id = p_id;
end;
$$;

-- 4. El listado del admin devuelve también el aviso del cliente
drop function if exists admin_list_orders();

create function admin_list_orders()
returns table (
  id uuid, company_id uuid, company_name text, quote_id uuid, quote_number bigint,
  prompt_text text, pricing jsonb, target_mode text, target_role text, target_employee_name text,
  order_number bigint, stage text, history jsonb, estimated_delivery date, last_note text,
  created_at timestamptz, updated_at timestamptz,
  client_alert text, client_alert_at timestamptz
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
      o.created_at, o.updated_at,
      o.client_alert, o.client_alert_at
    from company_orders o
    join company_dot_quote_requests q on q.id = o.quote_id
    left join company_profile cp on cp.id = o.company_id
    order by o.created_at desc;
end;
$$;

grant execute on function admin_list_orders() to authenticated;
