-- Migración: varios logos por diseño de Dotacian Studio
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: en /app/uniformes/studio el cliente puede poner hasta 5 logos
-- por prenda (pecho, espalda, nuca, mangas...). Se guardan como lista:
--   [{ "path": "<company_id>/<archivo>", "nombre": "logo.png",
--      "ubicacion": "pechoIzq", "ancho_cm": 7 }, ...]
-- El primer logo se sigue guardando también en logo_path, logo_nombre,
-- logo_ubicacion y logo_ancho_cm para no romper lo que ya los usa.

alter table studio_designs add column if not exists logos jsonb;

-- Diseños existentes: su logo único pasa a la lista.
update studio_designs
set logos = jsonb_build_array(jsonb_build_object(
  'path', logo_path, 'nombre', logo_nombre, 'ubicacion', logo_ubicacion, 'ancho_cm', logo_ancho_cm))
where logo_path is not null and logos is null;
