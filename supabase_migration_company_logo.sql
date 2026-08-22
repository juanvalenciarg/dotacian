-- Migración: logo de empresa (branding) por cliente
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: desde admin.empresas.html (panel interno) se podrá subir el
-- logo de cada empresa cliente, para mostrarlo en su propia instancia de
-- app/*.html (esquina superior derecha) y personalizar la plataforma por
-- empresa. Se usa un bucket nuevo "company-logos", separado del bucket
-- "logos" que ya existe (ese es para logos de bordado/estampado de prenda
-- en configurar-prenda.html, un concepto distinto con sus propias policies).

-- 1. Columna donde se guarda la URL pública del logo.
alter table company_profile
  add column if not exists logo_url text;

-- 2. Bucket "company-logos": créalo desde el dashboard de Supabase
--    (Storage → New bucket → nombre "company-logos" → marca "Public bucket"),
--    no por SQL, para evitar problemas de permisos sobre storage.buckets.

-- 3. Policies: lectura pública, escritura para cualquier usuario autenticado
--    (solo admin.empresas.html, panel interno, sube archivos a este bucket).
drop policy if exists "company_logos_public_read" on storage.objects;
create policy "company_logos_public_read" on storage.objects
  for select using (bucket_id = 'company-logos');

drop policy if exists "company_logos_write" on storage.objects;
create policy "company_logos_write" on storage.objects
  for insert to authenticated with check (bucket_id = 'company-logos');

drop policy if exists "company_logos_update" on storage.objects;
create policy "company_logos_update" on storage.objects
  for update to authenticated using (bucket_id = 'company-logos');
