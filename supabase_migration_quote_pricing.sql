-- Migración: precios de las cotizaciones
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: en Gestión de Cotizaciones (admin.cotizaciones.html) el equipo
-- de Dotacian pone el precio a cada prenda de la solicitud, más muestras,
-- envío e IVA. Se guarda en la propia solicitud para que salga en el PDF y
-- para que el cliente lo vea en Bodega → Mis cotizaciones cuando la
-- cotización se marque como "entregada".
--
-- Formato de pricing:
--   { currency, tax_rate, validity_days, samples_cost, shipping_cost,
--     items: [{ name, size, qty, unit_price }],
--     subtotal, tax, total }

-- 1. Columnas
alter table company_dot_quote_requests
  add column if not exists pricing jsonb;

alter table company_dot_quote_requests
  add column if not exists priced_at timestamptz;

-- 2. Guardar precios desde el panel admin
create or replace function admin_save_dot_quote_pricing(p_id uuid, p_pricing jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from admin_profile where admin_profile.id = auth.uid()) then
    raise exception 'No autorizado';
  end if;

  update company_dot_quote_requests
  set pricing = p_pricing,
      priced_at = now(),
      status = case when status = 'nueva' then 'en_proceso' else status end,
      status_updated_at = case when status = 'nueva' then now() else status_updated_at end
  where id = p_id;
end;
$$;

grant execute on function admin_save_dot_quote_pricing(uuid, jsonb) to authenticated;

-- 3. El listado del panel admin devuelve también los precios
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
  priced_at timestamptz
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
      q.quote_number, q.pricing, q.priced_at
    from company_dot_quote_requests q
    left join company_profile cp on cp.id = q.company_id
    order by q.created_at desc;
end;
$$;

grant execute on function admin_list_dot_quote_requests() to authenticated;
