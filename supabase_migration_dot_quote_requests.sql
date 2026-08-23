-- Migración: solicitudes de cotización capturadas por el chat "Cotizar con
-- Dot" (app/bodega.html y app/empleados.html) + RPCs para que el panel
-- admin.cotizaciones.html las liste y genere el PDF.
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: el chat de Dot es por ahora una simulación (no hay IA real
-- todavía) — captura el prompt libre del usuario y, en app/bodega.html,
-- si es para un rol o una persona puntual. Antes esto no se guardaba en
-- ningún lado; esta tabla le da persistencia para que el panel de admin
-- (Gestión de Cotizaciones) pueda verlas y armar el PDF de solicitud de
-- cotización, tal como antes lo hacía generarCotizacionDot() directamente
-- desde la app del cliente.

create table if not exists company_dot_quote_requests (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null,
  prompt_text text not null,
  target_mode text not null check (target_mode in ('rol', 'empleado')),
  target_role text,
  target_employee_id uuid,
  target_employee_name text,
  -- Solo se llenan cuando la solicitud viene del botón "Cotizar con Dot"
  -- de un activo puntual en app/empleados.html (cotizarActivoFaltante).
  item_name text,
  item_qty int,
  item_size text,
  status text not null default 'pendiente' check (status in ('pendiente', 'generado')),
  pdf_generated_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists company_dot_quote_requests_company_idx
  on company_dot_quote_requests (company_id);

-- RLS: mismo criterio usado en las demás tablas de este módulo (ver
-- supabase_migration_stock_minimums.sql). Solo el equipo de la empresa
-- puede ver/crear sus propias solicitudes; actualizar el estado a
-- "generado" queda reservado al panel admin vía RPC (más abajo).
alter table company_dot_quote_requests enable row level security;

create policy "company_dot_quote_requests_select" on company_dot_quote_requests
  for select using (
    company_id = auth.uid()
    or company_id in (select company_id from company_user where id = auth.uid())
  );

create policy "company_dot_quote_requests_insert" on company_dot_quote_requests
  for insert with check (
    company_id = auth.uid()
    or company_id in (select company_id from company_user where id = auth.uid())
  );

-- ── RPCs para admin.cotizaciones.html ──────────────────────────────────
-- Mismo patrón SECURITY DEFINER + chequeo de admin_profile que ya usa
-- este panel (ver supabase_migration_admin_create_company_user.sql). Se
-- devuelven también los datos de company_profile que necesita el PDF
-- (dirección de entrega, contacto, datos fiscales) para no depender de
-- que el admin tenga acceso de lectura a esa tabla vía RLS normal.

create or replace function admin_list_dot_quote_requests()
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
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from admin_profile where id = auth.uid()) then
    raise exception 'No autorizado';
  end if;

  return query
    select
      q.id, q.company_id, cp.company_name, cp.legal_name, cp.tax_id, cp.dv, cp.country,
      cp.delivery_address, cp.delivery_state,
      cp.delivery_contact_1_name, cp.delivery_contact_1_phone, cp.delivery_contact_1_email,
      q.prompt_text, q.target_mode, q.target_role, q.target_employee_id, q.target_employee_name,
      q.item_name, q.item_qty, q.item_size, q.status, q.pdf_generated_at, q.created_at
    from company_dot_quote_requests q
    left join company_profile cp on cp.id = q.company_id
    order by q.created_at desc;
end;
$$;

grant execute on function admin_list_dot_quote_requests() to authenticated;

create or replace function admin_mark_dot_quote_generated(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from admin_profile where id = auth.uid()) then
    raise exception 'No autorizado';
  end if;

  update company_dot_quote_requests
  set status = 'generado', pdf_generated_at = now()
  where id = p_id;
end;
$$;

grant execute on function admin_mark_dot_quote_generated(uuid) to authenticated;
