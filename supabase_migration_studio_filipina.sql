-- Migración: agregar la Filipina de chef al catálogo de Dotacian Studio
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- La clave 'filipina' coincide con el modelo 3D de app/studio.html.
-- Queda sugerida para Restaurantes y Hotelería (aparece marcada al crear
-- empresas de esas industrias). No se habilita a ninguna empresa existente:
-- hazlo desde DS Hub → Por empresa.

insert into studio_garments (key, nombre, descripcion, orden) values
  ('filipina', 'Filipina de chef', 'Cuello mao · Doble botonadura · Manga larga', 4)
on conflict (key) do nothing;

insert into studio_garment_industries (garment_key, industria) values
  ('filipina', 'restaurantes'),
  ('filipina', 'hoteleria')
on conflict do nothing;
