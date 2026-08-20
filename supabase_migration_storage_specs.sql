-- Migración: specs por lote en company_storage.
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: al agregar inventario en Bodega ahora se pueden capturar las
-- mismas especificaciones que ya se definen al asignar un activo a un rol
-- (marca, referencia, y características propias del tipo de activo, ej.
-- RAM/procesador para Laptop o norma/tipo para Casco). Se guardan por lote
-- (cada fila de company_storage que crea un ajuste de "Agregar activos"),
-- ya que dos lotes del mismo producto pueden tener specs distintas.

alter table company_storage
  add column if not exists specs jsonb;
