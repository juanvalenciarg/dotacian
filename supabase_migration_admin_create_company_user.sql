-- Migración: RPCs para que el panel de staff (admin.empresas.html) pueda
-- crear empresas y administradores.
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: "Nueva Empresa" y "Agregar Administrador" hacían upsert directo
-- a company_user/company_profile usando la sesión del staff logueado, pero
-- la fila que intentan escribir pertenece a OTRO usuario (el que se acaba
-- de crear). RLS rechaza eso (403 "new row violates row-level security
-- policy"), y en "Nueva Empresa" ese error quedaba silenciado con un
-- console.warn, dejando la empresa creada pero con 0 administradores.
--
-- Mismo patrón que ya usa este panel para borrar cuentas (delete_user_admin):
-- una función SECURITY DEFINER que salta RLS, pero solo si quien la llama
-- está en admin_profile.

create or replace function admin_create_company(
  p_owner_id uuid,
  p_company_name text,
  p_industry text,
  p_country text,
  p_first_name text,
  p_last_name text,
  p_email text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from admin_profile where id = auth.uid()) then
    raise exception 'No autorizado';
  end if;

  insert into company_profile (id, company_name, industry, country)
  values (p_owner_id, p_company_name, p_industry, p_country)
  on conflict (id) do update set
    company_name = excluded.company_name,
    industry = excluded.industry,
    country = excluded.country;

  insert into company_user (id, first_name, last_name, email, company_id, created_at)
  values (p_owner_id, p_first_name, p_last_name, p_email, null, now())
  on conflict (id) do update set
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    email = excluded.email;
end;
$$;

grant execute on function admin_create_company(uuid, text, text, text, text, text, text) to authenticated;

create or replace function admin_create_company_admin(
  p_user_id uuid,
  p_company_id uuid,
  p_first_name text,
  p_last_name text,
  p_email text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from admin_profile where id = auth.uid()) then
    raise exception 'No autorizado';
  end if;

  insert into company_user (id, first_name, last_name, email, company_id, created_at)
  values (p_user_id, p_first_name, p_last_name, p_email, p_company_id, now())
  on conflict (id) do update set
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    email = excluded.email,
    company_id = excluded.company_id;
end;
$$;

grant execute on function admin_create_company_admin(uuid, uuid, text, text, text) to authenticated;
