-- Migración: agregar la Camisa antifluido para personal de aseo al catálogo de Dotacian Studio
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- La clave 'camisa_aseo' coincide con la prenda de app/studio.html.
-- Corte de hombre y de mujer. Colores: toda la paleta, con vivos de manga y
-- franjas de bolsillo en gris claro por defecto (definidos en el código).
-- Queda sugerida para Limpieza, Salud y Hotelería. No se habilita a ninguna
-- empresa existente: hazlo desde DS Hub → Por empresa.

insert into studio_garments (key, nombre, descripcion, orden) values
  ('camisa_aseo', 'Camisa antifluido para aseo', 'Hombre y mujer · Cremallera · Vivos y bolsillos con franja', 9)
on conflict (key) do nothing;

insert into studio_garment_industries (garment_key, industria) values
  ('camisa_aseo', 'limpieza'),
  ('camisa_aseo', 'salud'),
  ('camisa_aseo', 'hoteleria')
on conflict do nothing;
