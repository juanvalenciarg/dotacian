-- Migración: separar "contacto" de company_asset_providers en correo (obligatorio
-- en la app) y teléfono (opcional, para cuando los agentes de voz puedan cotizar
-- por teléfono o WhatsApp más adelante).
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
-- Requiere haber corrido antes supabase_migration_asset_providers.sql.

-- 1. Nuevas columnas
alter table company_asset_providers
  add column if not exists correo text,
  add column if not exists telefono text;

-- 2. Migrar los datos existentes de "contacto": si parece correo (tiene "@")
--    se copia a correo; si no, se asume teléfono.
update company_asset_providers
  set correo = contacto
  where contacto is not null and contacto like '%@%' and correo is null;

update company_asset_providers
  set telefono = contacto
  where contacto is not null and contacto not like '%@%' and telefono is null;

-- 3. Ya no se usa la columna combinada.
--    ⚠️ Los proveedores migrados como teléfono (sin "@") quedan sin correo;
--    la app ya no los deja editar sin completarlo, pero el dato existente
--    no se pierde (queda en `telefono`).
alter table company_asset_providers
  drop column if exists contacto;
