-- Migración: el admin de Dotacian puede ver los diseños de Studio de los clientes
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: para cotizar, Gestión de Cotizaciones (admin.cotizaciones.html)
-- muestra la prenda, el color y el logo de cada diseño de la solicitud. Las
-- tablas y el bucket de logos solo dejan leer a la propia empresa (RLS), así
-- que se agregan un RPC y una policy de lectura para los usuarios de
-- admin_profile.

-- 1. Diseños de una empresa
create or replace function admin_list_studio_designs(p_company_id uuid)
returns setof studio_designs
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from admin_profile where admin_profile.id = auth.uid()) then
    raise exception 'No autorizado';
  end if;

  return query
    select * from studio_designs
    where company_id = p_company_id
    order by updated_at desc;
end;
$$;

grant execute on function admin_list_studio_designs(uuid) to authenticated;

-- 2. Lectura de los logos (bucket privado studio-logos) para el admin
drop policy if exists "studio_logos_admin_select" on storage.objects;
create policy "studio_logos_admin_select" on storage.objects
  for select to authenticated using (
    bucket_id = 'studio-logos'
    and exists (select 1 from admin_profile where admin_profile.id = auth.uid())
  );
