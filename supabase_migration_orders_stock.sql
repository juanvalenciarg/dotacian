-- Migración: al entregarse un pedido, sus prendas entran al stock de Bodega
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
-- Requiere supabase_migration_orders.sql y las migraciones de company_storage
-- (role_id, unit_cost).
--
-- Contexto: cuando un pedido pasa a "entregado" (lo marca el admin en
-- Gestión de Pedidos o el cliente con "Confirmar recibido"), cada prenda de la
-- cotización aprobada se agrega a company_storage como stock nuevo del rol de
-- la cotización, con el precio unitario como costo. Se hace una sola vez por
-- pedido (stock_added_at), aunque el pedido vuelva a cambiar de etapa.

alter table company_orders add column if not exists stock_added_at timestamptz;

create or replace function add_delivered_order_to_storage()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_quote record;
  v_role_id uuid;
  v_item jsonb;
  v_items jsonb;
  v_total int := 0;
  v_qty int;
  v_sku text;
begin
  if new.stage <> 'entregado' or old.stage = 'entregado' or new.stock_added_at is not null then
    return new;
  end if;

  select * into v_quote from company_dot_quote_requests where id = new.quote_id;
  if v_quote.id is null then
    return new;
  end if;

  -- Prendas: las de la cotización con precios o, si no tiene, la prenda única.
  if v_quote.pricing is not null and jsonb_typeof(v_quote.pricing -> 'items') = 'array' then
    v_items := v_quote.pricing -> 'items';
  elsif v_quote.item_name is not null then
    v_items := jsonb_build_array(jsonb_build_object(
      'name', v_quote.item_name, 'size', v_quote.item_size, 'qty', coalesce(v_quote.item_qty, 1)));
  else
    v_items := '[]'::jsonb;
  end if;

  select id into v_role_id
  from role_definition
  where company_id = v_quote.company_id
    and lower(btrim(role_name)) = lower(btrim(coalesce(v_quote.target_role, '')))
  limit 1;

  v_sku := 'PED-' || lpad(new.order_number::text, 4, '0');

  for v_item in select * from jsonb_array_elements(v_items) loop
    v_qty := coalesce((v_item ->> 'qty')::int, 0);
    if coalesce(btrim(v_item ->> 'name'), '') = '' or v_qty <= 0 then
      continue;
    end if;
    insert into company_storage (company_id, sku, product_name, category, size, quantity, status, role_id, unit_cost)
    values (
      v_quote.company_id,
      v_sku,
      btrim(v_item ->> 'name'),
      'Pedido Dotacian',
      coalesce(nullif(btrim(v_item ->> 'size'), ''), 'Unitalla'),
      v_qty,
      'available',
      v_role_id,
      nullif(v_item ->> 'unit_price', '')::numeric
    );
    v_total := v_total + v_qty;
  end loop;

  new.stock_added_at := now();
  if v_total > 0 then
    new.history := new.history || jsonb_build_array(jsonb_build_object(
      'stage', 'entregado', 'at', now(),
      'note', 'Se sumaron ' || v_total || ' prendas a la bodega'));
  end if;
  return new;
end;
$$;

drop trigger if exists company_orders_add_to_storage on company_orders;
create trigger company_orders_add_to_storage
  before update of stage on company_orders
  for each row execute function add_delivered_order_to_storage();
