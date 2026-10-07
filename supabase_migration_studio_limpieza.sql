-- Migración: agregar el Uniforme de limpieza (túnica + pantalón) al catálogo de Dotacian Studio
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- La clave 'limpieza' coincide con el modelo 3D de app/studio.html.
-- Colores: azul marino, negro y gris, con vivos blancos (definidos en el código).
-- Queda sugerido para Limpieza, Salud y Hotelería. No se habilita a ninguna
-- empresa existente: hazlo desde DS Hub → Por empresa.

insert into studio_garments (key, nombre, descripcion, orden) values
  ('limpieza', 'Uniforme de limpieza', 'Túnica con vivos + pantalón de resorte', 7)
on conflict (key) do nothing;

insert into studio_garment_industries (garment_key, industria) values
  ('limpieza', 'limpieza'),
  ('limpieza', 'salud'),
  ('limpieza', 'hoteleria')
on conflict do nothing;
