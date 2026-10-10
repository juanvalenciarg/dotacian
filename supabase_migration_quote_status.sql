-- Migración: estados de las solicitudes de cotización
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: Gestión de Cotizaciones (admin.cotizaciones.html) pasa de
-- "pendiente / generado" a un flujo de tres estados que el admin cambia a
-- mano y que el cliente ve en Bodega → Mis cotizaciones:
--   nueva       → recién enviada por el cliente
--   en_proceso  → el equipo la está trabajando (o ya generó el PDF)
--   entregada   → la cotización ya se le entregó al cliente

-- 1. Nuevos valores de estado (los existentes se convierten)
alter table company_dot_quote_requests
  drop constraint if exists company_dot_quote_requests_status_check;

update company_dot_quote_requests set status = 'nueva' where status = 'pendiente';
update company_dot_quote_requests set status = 'en_proceso' where status = 'generado';

alter table company_dot_quote_requests
  alter column status set default 'nueva';

alter table company_dot_quote_requests
  add constraint company_dot_quote_requests_status_check
  check (status in ('nueva', 'en_proceso', 'entregada'));

alter table company_dot_quote_requests
  add column if not exists status_updated_at timestamptz;

-- 2. Generar el PDF ya no fuerza el estado final: si estaba "nueva" pasa a
--    "en_proceso"; si ya estaba más adelante, se respeta.
create or replace function admin_mark_dot_quote_generated(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from admin_profile where admin_profile.id = auth.uid()) then
    raise exception 'No autorizado';
  end if;

  update company_dot_quote_requests
  set pdf_generated_at = now(),
      status = case when status = 'nueva' then 'en_proceso' else status end,
      status_updated_at = case when status = 'nueva' then now() else status_updated_at end
  where id = p_id;
end;
$$;

-- 3. Cambiar el estado a mano desde el panel admin
create or replace function admin_set_dot_quote_status(p_id uuid, p_status text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from admin_profile where admin_profile.id = auth.uid()) then
    raise exception 'No autorizado';
  end if;

  if p_status not in ('nueva', 'en_proceso', 'entregada') then
    raise exception 'Estado inválido: %', p_status;
  end if;

  update company_dot_quote_requests
  set status = p_status, status_updated_at = now()
  where id = p_id;
end;
$$;

grant execute on function admin_set_dot_quote_status(uuid, text) to authenticated;
