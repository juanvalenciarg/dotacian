-- Migración: agregar la Bata al catálogo de Dotacian Studio
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- La clave 'bata' coincide con el modelo 3D de app/studio.html.
-- Colores: gris grafito, azul marino, negro y gris, con cuello y franjas de
-- los bolsillos en vinotinto (definidos en el código).
-- Queda sugerida para Limpieza, Salud y Hotelería. No se habilita a ninguna
-- empresa existente: hazlo desde DS Hub → Por empresa.

insert into studio_garments (key, nombre, descripcion, orden) values
  ('bata', 'Bata', 'Cuello en contraste · Cremallera · Bolsillos con franja', 8)
on conflict (key) do nothing;

insert into studio_garment_industries (garment_key, industria) values
  ('bata', 'limpieza'),
  ('bata', 'salud'),
  ('bata', 'hoteleria')
on conflict do nothing;
