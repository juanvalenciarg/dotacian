-- Migración: DS Hub (prendas de Dotacian Studio visibles por industria)
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: desde el panel admin (admin.studio.html, "DS Hub") el
-- equipo de Dotacian decide qué prendas (modelos 3D) puede diseñar cada
-- industria en Dotacian Studio (/app/uniformes/studio). Las empresas sin
-- industria válida solo ven la camiseta básica.
--
-- Industrias válidas (las mismas claves de configuracion.html y onboarding.html):
-- restaurantes, limpieza, industrial, corporate, seguridad, hoteleria,
-- retail, salud, construccion, logistica.

-- 1. Catálogo de prendas. La clave debe coincidir con el modelo 3D del código
--    (GARMENTS en app/studio.html).
create table if not exists studio_garments (
  key text primary key,
  nombre text not null,
  descripcion text,
  activo boolean not null default true,  -- apagada = no la ve ninguna empresa
  orden int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into studio_garments (key, nombre, descripcion, orden) values
  ('camiseta', 'Camiseta básica', 'Cuello redondo · Manga corta', 1),
  ('camisa', 'Camisa manga larga', 'Cuello camisero · Botones · Bolsillo', 2),
  ('hoodie', 'Hoodie', 'Capucha · Bolsillo canguro · Puños en rib', 3)
on conflict (key) do nothing;

-- 2. Visibilidad: qué prenda está habilitada en qué industria.
create table if not exists studio_garment_industries (
  garment_key text not null references studio_garments(key) on delete cascade,
  industria text not null check (industria in (
    'restaurantes', 'limpieza', 'industrial', 'corporate', 'seguridad',
    'hoteleria', 'retail', 'salud', 'construccion', 'logistica'
  )),
  created_at timestamptz not null default now(),
  primary key (garment_key, industria)
);

-- Arranque: las tres prendas actuales quedan habilitadas en todas las
-- industrias para que nadie pierda lo que ya veía. Ajústalo luego desde
-- DS Hub.
insert into studio_garment_industries (garment_key, industria)
select g.key, i.industria
from studio_garments g
cross join (values ('restaurantes'), ('limpieza'), ('industrial'), ('corporate'), ('seguridad'),
                   ('hoteleria'), ('retail'), ('salud'), ('construccion'), ('logistica')) as i(industria)
on conflict do nothing;

-- 3. Acceso: cualquier usuario con sesión puede leer el catálogo; solo los
--    administradores (admin_profile) pueden modificarlo.
alter table studio_garments enable row level security;
alter table studio_garment_industries enable row level security;

drop policy if exists "studio_garments_read" on studio_garments;
create policy "studio_garments_read" on studio_garments
  for select to authenticated using (true);

drop policy if exists "studio_garments_admin_write" on studio_garments;
create policy "studio_garments_admin_write" on studio_garments
  for all to authenticated
  using (exists (select 1 from admin_profile where id = auth.uid()))
  with check (exists (select 1 from admin_profile where id = auth.uid()));

drop policy if exists "studio_garment_industries_read" on studio_garment_industries;
create policy "studio_garment_industries_read" on studio_garment_industries
  for select to authenticated using (true);

drop policy if exists "studio_garment_industries_admin_write" on studio_garment_industries;
create policy "studio_garment_industries_admin_write" on studio_garment_industries
  for all to authenticated
  using (exists (select 1 from admin_profile where id = auth.uid()))
  with check (exists (select 1 from admin_profile where id = auth.uid()));

-- 4. Prendas que puede diseñar la empresa del usuario actual.
--    SECURITY DEFINER: así un miembro del equipo (company_user) puede saber
--    la industria de su empresa sin necesitar permiso de lectura sobre
--    company_profile. Si la empresa no tiene una industria válida, o su
--    industria no tiene prendas habilitadas, devuelve solo la camiseta básica.
create or replace function studio_garments_for_me()
returns table (garment_key text)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company uuid;
  v_industry text;
begin
  select coalesce(
    (select cp.id from company_profile cp where cp.id = auth.uid()),
    (select cu.company_id from company_user cu where cu.id = auth.uid())
  ) into v_company;

  select lower(btrim(cp.industry)) into v_industry
  from company_profile cp
  where cp.id = v_company;

  return query
    select g.key
    from studio_garments g
    join studio_garment_industries gi on gi.garment_key = g.key
    where g.activo and gi.industria = v_industry
    order by g.orden;

  if not found then
    return query select 'camiseta'::text;
  end if;
end;
$$;

grant execute on function studio_garments_for_me() to authenticated;

-- 5. Revisión: empresas cuya industria no está en la lista (quedan viendo solo
--    la camiseta básica hasta que les asignes una desde Admin → Empresas).
-- select id, company_name, industry from company_profile
-- where industry is null
--    or lower(btrim(industry)) not in ('restaurantes', 'limpieza', 'industrial', 'corporate', 'seguridad',
--                                      'hoteleria', 'retail', 'salud', 'construccion', 'logistica');
