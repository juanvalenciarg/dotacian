-- Migración: número consecutivo de cotización (COT-0001, COT-0002, ...)
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: cada solicitud de cotización (manual o de Dot) necesita un
-- número para identificarla con el cliente. Se muestra en Gestión de
-- Cotizaciones, en el PDF y en Bodega → Mis cotizaciones.

-- 1. Columna y numeración de las solicitudes existentes (por fecha)
alter table company_dot_quote_requests
  add column if not exists quote_number bigint;

update company_dot_quote_requests q
set quote_number = n.rn
from (
  select id, row_number() over (order by created_at, id) as rn
  from company_dot_quote_requests
) n
where q.id = n.id and q.quote_number is null;

-- 2. Las nuevas toman el siguiente número automáticamente
create sequence if not exists company_dot_quote_requests_number_seq;
select setval(
  'company_dot_quote_requests_number_seq',
  greatest((select coalesce(max(quote_number), 0) from company_dot_quote_requests), 1),
  (select count(*) > 0 from company_dot_quote_requests)
);
alter sequence company_dot_quote_requests_number_seq owned by company_dot_quote_requests.quote_number;
-- El cliente inserta sus solicitudes desde la app: necesita usar la secuencia.
grant usage, select on sequence company_dot_quote_requests_number_seq to authenticated;

alter table company_dot_quote_requests
  alter column quote_number set default nextval('company_dot_quote_requests_number_seq');

alter table company_dot_quote_requests
  alter column quote_number set not null;

create unique index if not exists company_dot_quote_requests_number_idx
  on company_dot_quote_requests (quote_number);

-- 3. El listado del panel admin devuelve también el número (cambia el tipo
--    de retorno, por eso hay que borrar la función antes de recrearla).
drop function if exists admin_list_dot_quote_requests();

create function admin_list_dot_quote_requests()
returns table (
  id uuid,
  company_id uuid,
  company_name text,
  legal_name text,
  tax_id text,
  dv text,
  country text,
  delivery_address text,
  delivery_state text,
  delivery_contact_1_name text,
  delivery_contact_1_phone text,
  delivery_contact_1_email text,
  prompt_text text,
  target_mode text,
  target_role text,
  target_employee_id uuid,
  target_employee_name text,
  item_name text,
  item_qty int,
  item_size text,
  status text,
  pdf_generated_at timestamptz,
  created_at timestamptz,
  quote_number bigint
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from admin_profile where admin_profile.id = auth.uid()) then
    raise exception 'No autorizado';
  end if;

  return query
    select
      q.id, q.company_id,
      cp.company_name::text, cp.legal_name::text, cp.tax_id::text, cp.dv::text, cp.country::text,
      cp.delivery_address::text, cp.delivery_state::text,
      cp.delivery_contact_1_name::text, cp.delivery_contact_1_phone::text, cp.delivery_contact_1_email::text,
      q.prompt_text, q.target_mode, q.target_role, q.target_employee_id, q.target_employee_name,
      q.item_name, q.item_qty, q.item_size, q.status, q.pdf_generated_at, q.created_at,
      q.quote_number
    from company_dot_quote_requests q
    left join company_profile cp on cp.id = q.company_id
    order by q.created_at desc;
end;
$$;

grant execute on function admin_list_dot_quote_requests() to authenticated;
