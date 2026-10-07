-- Migración: agregar el Pantalón chino al catálogo de Dotacian Studio
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- La clave 'pantalon' coincide con el modelo 3D de app/studio.html.
-- Colores del pantalón: negro, beige y azul (definidos en el código).
-- Queda sugerido para Corporativo, Retail, Hotelería, Restaurantes y
-- Logística. No se habilita a ninguna empresa existente: hazlo desde
-- DS Hub → Por empresa.

insert into studio_garments (key, nombre, descripcion, orden) values
  ('pantalon', 'Pantalón chino', 'Pretina con pasadores · Bolsillos sesgados', 6)
on conflict (key) do nothing;

insert into studio_garment_industries (garment_key, industria) values
  ('pantalon', 'corporate'),
  ('pantalon', 'retail'),
  ('pantalon', 'hoteleria'),
  ('pantalon', 'restaurantes'),
  ('pantalon', 'logistica')
on conflict do nothing;
