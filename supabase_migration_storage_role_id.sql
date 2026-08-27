-- Migración: ligar cada lote de company_storage a un rol específico.
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: dos roles distintos pueden tener un ítem con el mismo nombre
-- (ej. "Camiseta/Camisa") pero ser prendas físicamente distintas (specs,
-- color, tela). Hoy el stock se agrupa solo por product_name + talla y
-- termina compartido entre roles. role_id permite separar el conteo por
-- rol de punta a punta (Cotizaciones -> Órdenes -> Envíos -> Bodega).
-- Nullable a propósito: los lotes históricos no tienen forma confiable de
-- inferir a qué rol pertenecían, así que quedan "sin rol asignado".

alter table company_storage
  add column if not exists role_id uuid references role_definition(id) on delete set null;

create index if not exists idx_company_storage_role_id
  on company_storage (role_id);
