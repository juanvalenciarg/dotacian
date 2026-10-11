-- Migración: agregar el Buzo (sin capucha) al catálogo de Dotacian Studio
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- La clave 'buzo' coincide con el modelo 3D de app/studio.html. El hoodie
-- queda siempre con capucha y el buzo es la versión sin capucha (cuello
-- redondo o alto en rib, media cremallera opcional).
-- Se sugiere en las mismas industrias que el hoodie y se habilita a las
-- empresas que hoy tienen el hoodie, para que no tengan que pedirlo.

insert into studio_garments (key, nombre, descripcion, orden) values
  ('buzo', 'Buzo', 'Cuello redondo · Puños en rib', 4)
on conflict (key) do nothing;

insert into studio_garment_industries (garment_key, industria)
select 'buzo', industria from studio_garment_industries where garment_key = 'hoodie'
on conflict do nothing;

insert into studio_company_garments (company_id, garment_key)
select company_id, 'buzo' from studio_company_garments where garment_key = 'hoodie'
on conflict do nothing;
