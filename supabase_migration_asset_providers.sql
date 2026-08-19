-- Migración: proveedores múltiples + parametrización de ciclo de vida para company_assets
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: la sección "Activos" pasa de un solo proveedor por activo a una lista
-- de proveedores (nombre + contacto básico), y suma tres parámetros de ciclo de
-- vida que hoy no existían: si el activo es renovable (y cada cuántos meses),
-- si se devuelve en el offboarding del empleado, y si se reutiliza con el
-- siguiente empleado (esta última ya existía como `reutilizable`).

-- 1. Nuevas columnas de ciclo de vida en company_assets
alter table company_assets
  add column if not exists es_renovable boolean not null default false,
  add column if not exists renovacion_meses int,
  add column if not exists devolvible_offboarding boolean not null default true;

-- 2. Tabla de proveedores (uno a muchos por activo)
create table if not exists company_asset_providers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null,
  company_asset_id uuid not null references company_assets(id) on delete cascade,
  nombre text not null,
  contacto text,
  created_at timestamptz not null default now()
);

create index if not exists company_asset_providers_asset_idx
  on company_asset_providers (company_asset_id);

create index if not exists company_asset_providers_company_idx
  on company_asset_providers (company_id);

-- 3. RLS: mismo criterio de acceso que ya tienes en company_assets.
--    Ajusta esta policy si tu policy real en company_assets usa otra condición
--    (esto replica el patrón de resolveCompanyId en assets/js/utils.js: el
--    company_id es el propio auth.uid() del dueño, o el company_id asociado
--    en company_user para miembros del equipo).
alter table company_asset_providers enable row level security;

create policy "company_asset_providers_select" on company_asset_providers
  for select using (
    company_id = auth.uid()
    or company_id in (select company_id from company_user where id = auth.uid())
  );

create policy "company_asset_providers_write" on company_asset_providers
  for all using (
    company_id = auth.uid()
    or company_id in (select company_id from company_user where id = auth.uid())
  ) with check (
    company_id = auth.uid()
    or company_id in (select company_id from company_user where id = auth.uid())
  );

-- 4. Migrar el proveedor único existente (si lo hay) a la tabla nueva,
--    para no perder datos ya cargados.
insert into company_asset_providers (company_id, company_asset_id, nombre, contacto)
select company_id, id, proveedor_nombre, proveedor_contacto
from company_assets
where proveedor_nombre is not null and proveedor_nombre <> '';

-- 5. Columnas que ya no se usan desde el nuevo panel de Activos:
--    - proveedor_nombre / proveedor_contacto -> reemplazadas por company_asset_providers
--    - precio_unitario / tiempo_entrega_dias -> eran por-proveedor, se piden en la
--      cotización que arma el agente, no aquí
--    - colores -> es detalle de ítem (marca/referencia/talla/etc.), se moverá a Roles
--    ⚠️ Esto borra esos datos de forma permanente. El paso 4 ya copió el proveedor
--    único a la tabla nueva; si quieres conservar precio_unitario, tiempo_entrega_dias
--    o colores, respáldalos antes de correr este bloque (o comenta estas líneas).
alter table company_assets
  drop column if exists proveedor_nombre,
  drop column if exists proveedor_contacto,
  drop column if exists precio_unitario,
  drop column if exists tiempo_entrega_dias,
  drop column if exists colores;
