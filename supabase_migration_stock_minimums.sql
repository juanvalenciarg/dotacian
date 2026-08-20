-- Migración: mínimos de stock reales por producto+talla en Bodega.
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: "Configuración de Stock Mínimo" en app/bodega.html era un modal
-- con filas hardcodeadas (Camisa Oxford, Mandil Barista...) y un
-- saveMinimos() que solo mostraba un alert() de éxito sin guardar nada.
-- Esta tabla le da persistencia real, para poder calcular qué activos
-- están bajo mínimo y ofrecer "Cotizar" sobre ellos usando los
-- proveedores registrados en Activos.

create table if not exists company_stock_minimums (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null,
  product_name text not null,
  talla text not null default 'N/A',
  minimo int not null default 0,
  updated_at timestamptz not null default now(),
  unique (company_id, product_name, talla)
);

create index if not exists company_stock_minimums_company_idx
  on company_stock_minimums (company_id);

-- RLS: mismo criterio usado en las demás tablas de este módulo (ver
-- supabase_migration_asset_providers.sql). Ajusta si tu policy real
-- en company_storage/company_assets usa otra condición.
alter table company_stock_minimums enable row level security;

create policy "company_stock_minimums_select" on company_stock_minimums
  for select using (
    company_id = auth.uid()
    or company_id in (select company_id from company_user where id = auth.uid())
  );

create policy "company_stock_minimums_write" on company_stock_minimums
  for all using (
    company_id = auth.uid()
    or company_id in (select company_id from company_user where id = auth.uid())
  ) with check (
    company_id = auth.uid()
    or company_id in (select company_id from company_user where id = auth.uid())
  );
