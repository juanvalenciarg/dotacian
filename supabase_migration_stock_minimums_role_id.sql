-- Migración: mínimos de stock por rol en company_stock_minimums.
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: complementa supabase_migration_storage_role_id.sql. Si el
-- stock ahora se separa por rol, el mínimo configurado también debe
-- poder ser distinto por rol (ej. mínimo de "Camiseta/Camisa" para
-- Administrador vs para Cajero).
--
-- Nota: el upsert de bodega.html usa onConflict='company_id,role_id,
-- product_name,talla', y PostgREST solo puede apuntar a una constraint/
-- índice único definido sobre esas columnas literales (no a un índice con
-- expresión tipo coalesce()). Por eso la unicidad es un constraint plano
-- sobre (company_id, role_id, product_name, talla). Limitación conocida:
-- Postgres trata cada NULL de role_id como distinto, así que si en algún
-- momento se guardan dos mínimos "sin rol" (role_id null) para el mismo
-- producto+talla, quedarían como dos filas en vez de una sola actualizada.
-- Es un caso de borde (stock histórico sin rol), no el camino principal.

alter table company_stock_minimums
  add column if not exists role_id uuid references role_definition(id) on delete set null;

alter table company_stock_minimums
  drop constraint if exists company_stock_minimums_company_id_product_name_talla_key;

alter table company_stock_minimums
  add constraint company_stock_minimums_company_role_product_talla_key
  unique (company_id, role_id, product_name, talla);
