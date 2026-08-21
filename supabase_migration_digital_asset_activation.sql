-- Migración: activación de activos digitales (licencias, accesos) por correo
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: los activos "digitales" (category = 'digital' en company_assets)
-- no se cotizan a un proveedor físico ni se entregan contra bodega (ver
-- comentario en app/empleados.html sobre "los digitales tendrán su propio
-- flujo"). En vez de proveedores, la empresa registra un contacto (la
-- persona que administra esa plataforma/sistema) y, al asignar el activo a
-- un empleado, el admin puede "solicitar activación" abriendo un correo
-- (mailto:) prellenado hacia ese contacto. Este cambio:
--   1) agrega el contacto de activación al catálogo de activos, y
--   2) crea una tabla para llevar el estado de esa solicitud por empleado.

-- 1. Contacto de activación en el catálogo (solo aplica a category = 'digital')
alter table company_assets
  add column if not exists contacto_encargado_nombre text,
  add column if not exists contacto_encargado_email text;

-- 2. Estado de activación por empleado + activo digital asignado
create table if not exists employee_digital_assets (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null,
  employee_id uuid not null,
  tipo text not null,
  nombre text not null,
  status text not null default 'pendiente' check (status in ('pendiente', 'solicitado', 'activado')),
  contacto_email text,
  solicitado_at timestamptz,
  activado_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (employee_id, tipo, nombre)
);

create index if not exists employee_digital_assets_employee_idx
  on employee_digital_assets (employee_id);

create index if not exists employee_digital_assets_company_idx
  on employee_digital_assets (company_id);

-- 3. RLS: mismo criterio de acceso que company_asset_providers.
alter table employee_digital_assets enable row level security;

create policy "employee_digital_assets_select" on employee_digital_assets
  for select using (
    company_id = auth.uid()
    or company_id in (select company_id from company_user where id = auth.uid())
  );

create policy "employee_digital_assets_write" on employee_digital_assets
  for all using (
    company_id = auth.uid()
    or company_id in (select company_id from company_user where id = auth.uid())
  ) with check (
    company_id = auth.uid()
    or company_id in (select company_id from company_user where id = auth.uid())
  );
