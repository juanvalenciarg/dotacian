-- Migración: prendas de Dotacian Studio habilitadas por empresa
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
-- Requiere haber corrido antes supabase_migration_studio_catalog.sql.
--
-- Contexto: cada empresa tiene su propia lista de prendas que puede diseñar
-- en Dotacian Studio. Se eligen al crear la empresa (Admin → Gestión de
-- Empresas → Crear Empresa) y después solo se cambian desde DS Hub.
-- La tabla por industria (studio_garment_industries) pasa a ser la lista de
-- prendas SUGERIDAS para cada industria al crear una empresa.

-- 1. Prendas habilitadas por empresa (company_id = company_profile.id)
create table if not exists studio_company_garments (
  company_id uuid not null,
  garment_key text not null references studio_garments(key) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (company_id, garment_key)
);

create index if not exists studio_company_garments_company_idx
  on studio_company_garments (company_id);

-- 2. Acceso: la empresa lee las suyas; solo los administradores las cambian.
alter table studio_company_garments enable row level security;

drop policy if exists "studio_company_garments_read" on studio_company_garments;
create policy "studio_company_garments_read" on studio_company_garments
  for select to authenticated using (
    company_id = auth.uid()
    or company_id in (select company_id from company_user where id = auth.uid())
    or exists (select 1 from admin_profile where id = auth.uid())
  );

drop policy if exists "studio_company_garments_admin_write" on studio_company_garments;
create policy "studio_company_garments_admin_write" on studio_company_garments
  for all to authenticated
  using (exists (select 1 from admin_profile where id = auth.uid()))
  with check (exists (select 1 from admin_profile where id = auth.uid()));

-- 3. Carga inicial para las empresas que ya existen: las prendas sugeridas
--    de su industria (hoy, todas). Las que no tienen industria válida quedan
--    con la camiseta básica. Así nadie deja de ver lo que ve hoy.
insert into studio_company_garments (company_id, garment_key)
select cp.id, gi.garment_key
from company_profile cp
join studio_garment_industries gi on gi.industria = lower(btrim(cp.industry))
on conflict do nothing;

insert into studio_company_garments (company_id, garment_key)
select cp.id, 'camiseta'
from company_profile cp
where not exists (select 1 from studio_company_garments scg where scg.company_id = cp.id)
on conflict do nothing;

-- 4. Prendas que puede diseñar la empresa del usuario actual: las habilitadas
--    para su empresa que estén activas en el catálogo. Si no tiene ninguna,
--    solo la camiseta básica.
create or replace function studio_garments_for_me()
returns table (garment_key text)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company uuid;
begin
  select coalesce(
    (select cp.id from company_profile cp where cp.id = auth.uid()),
    (select cu.company_id from company_user cu where cu.id = auth.uid())
  ) into v_company;

  return query
    select g.key
    from studio_garments g
    join studio_company_garments scg on scg.garment_key = g.key
    where g.activo and scg.company_id = v_company
    order by g.orden;

  if not found then
    return query select 'camiseta'::text;
  end if;
end;
$$;

grant execute on function studio_garments_for_me() to authenticated;
