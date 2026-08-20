-- Migración: valor de compra unitario por lote en company_storage.
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: al eliminarse el portal de vendedores, el "Valor del Inventario"
-- ya no se puede inferir de forma confiable desde seller_catalog.base_price.
-- Ahora se captura el costo de compra unitario directamente al agregar
-- inventario manualmente en Bodega, guardado por lote (cada fila que crea
-- un ajuste de "Agregar activos", ya que dos lotes del mismo producto pueden
-- tener costos distintos), y se usa como fuente principal para calcular el
-- KPI de "Valor del Inventario" (con el price map anterior como respaldo
-- para lotes que no tengan costo guardado).

alter table company_storage
  add column if not exists unit_cost numeric;
