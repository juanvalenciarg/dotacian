-- Migración: agregar la Camiseta tipo polo al catálogo de Dotacian Studio
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- La clave 'polo' coincide con el modelo 3D de app/studio.html.
-- Queda sugerida para Corporativo, Retail, Hotelería, Restaurantes y
-- Logística (aparece marcada al crear empresas de esas industrias). No se
-- habilita a ninguna empresa existente: hazlo desde DS Hub → Por empresa.

insert into studio_garments (key, nombre, descripcion, orden) values
  ('polo', 'Camiseta tipo polo', 'Cuello polo en rib · Tapeta con 2 botones', 5)
on conflict (key) do nothing;

insert into studio_garment_industries (garment_key, industria) values
  ('polo', 'corporate'),
  ('polo', 'retail'),
  ('polo', 'hoteleria'),
  ('polo', 'restaurantes'),
  ('polo', 'logistica')
on conflict do nothing;
