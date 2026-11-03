-- Migración: agregar el Camibuso al catálogo de Dotacian Studio
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- La clave 'camibuso' coincide con el modelo 3D de app/studio.html.
-- Queda sugerido para las mismas industrias que la camiseta básica. No se
-- habilita a ninguna empresa existente: hazlo desde DS Hub → Por empresa.

insert into studio_garments (key, nombre, descripcion, orden) values
  ('camibuso', 'Camibuso', 'Cuello redondo o en V · Manga larga', 2)
on conflict (key) do nothing;

insert into studio_garment_industries (garment_key, industria)
  select 'camibuso', industria from studio_garment_industries where garment_key = 'camiseta'
on conflict do nothing;
