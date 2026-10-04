-- Migración: diseños guardados de Dotacian Studio
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: en /app/uniformes/studio el cliente arma un diseño (prenda,
-- color y logo con su ubicación y tamaño) y ahora puede guardarlo con un
-- nombre para volver a abrirlo después. Cada diseño pertenece a una empresa
-- y solo lo ven los usuarios de esa empresa.

-- 1. Tabla de diseños
create table if not exists studio_designs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null,
  nombre text not null check (char_length(btrim(nombre)) between 1 and 80),
  prenda text not null,            -- 'camiseta' | 'camisa' | 'hoodie'
  color text not null,             -- 'blanco' | 'negro' | 'azul' | 'rojo'
  logo_path text,                  -- ruta del archivo en el bucket studio-logos
  logo_nombre text,                -- nombre original del archivo
  logo_ubicacion text,             -- 'pechoIzq' | 'pechoDer' | 'pechoCentro' | 'espalda'
  logo_ancho_cm int,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists studio_designs_company_idx
  on studio_designs (company_id, updated_at desc);

-- 2. RLS: mismo criterio que company_asset_providers (el company_id es el
--    propio auth.uid() del dueño, o el company_id de company_user para
--    miembros del equipo; ver resolveCompanyId en assets/js/utils.js).
alter table studio_designs enable row level security;

drop policy if exists "studio_designs_select" on studio_designs;
create policy "studio_designs_select" on studio_designs
  for select using (
    company_id = auth.uid()
    or company_id in (select company_id from company_user where id = auth.uid())
  );

drop policy if exists "studio_designs_write" on studio_designs;
create policy "studio_designs_write" on studio_designs
  for all using (
    company_id = auth.uid()
    or company_id in (select company_id from company_user where id = auth.uid())
  ) with check (
    company_id = auth.uid()
    or company_id in (select company_id from company_user where id = auth.uid())
  );

-- 3. Bucket "studio-logos": créalo desde el dashboard de Supabase
--    (Storage → New bucket → nombre "studio-logos" → deja "Public bucket"
--    DESMARCADO), no por SQL, para evitar problemas de permisos sobre
--    storage.buckets. Es privado: los logos de los clientes no quedan con
--    URL pública. Cada archivo se guarda en una carpeta con el company_id:
--    studio-logos/<company_id>/<archivo>.

-- 4. Policies del bucket: solo los usuarios de la empresa dueña de la
--    carpeta pueden ver, subir, reemplazar o borrar sus logos.
drop policy if exists "studio_logos_select" on storage.objects;
create policy "studio_logos_select" on storage.objects
  for select to authenticated using (
    bucket_id = 'studio-logos' and (
      (storage.foldername(name))[1] = auth.uid()::text
      or (storage.foldername(name))[1] in (select company_id::text from company_user where id = auth.uid())
    )
  );

drop policy if exists "studio_logos_insert" on storage.objects;
create policy "studio_logos_insert" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'studio-logos' and (
      (storage.foldername(name))[1] = auth.uid()::text
      or (storage.foldername(name))[1] in (select company_id::text from company_user where id = auth.uid())
    )
  );

drop policy if exists "studio_logos_update" on storage.objects;
create policy "studio_logos_update" on storage.objects
  for update to authenticated using (
    bucket_id = 'studio-logos' and (
      (storage.foldername(name))[1] = auth.uid()::text
      or (storage.foldername(name))[1] in (select company_id::text from company_user where id = auth.uid())
    )
  );

drop policy if exists "studio_logos_delete" on storage.objects;
create policy "studio_logos_delete" on storage.objects
  for delete to authenticated using (
    bucket_id = 'studio-logos' and (
      (storage.foldername(name))[1] = auth.uid()::text
      or (storage.foldername(name))[1] in (select company_id::text from company_user where id = auth.uid())
    )
  );
