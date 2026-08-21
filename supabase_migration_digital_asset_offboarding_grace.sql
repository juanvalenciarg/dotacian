-- Migración: periodo de gracia para revocar activos digitales
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
-- Requiere haber corrido antes:
--   1) supabase_migration_digital_asset_activation.sql
--   2) supabase_migration_digital_asset_offboarding.sql
--
-- Contexto: al dar de baja a un empleado, no todos los activos digitales se
-- deben desactivar de inmediato (ej. correo para transición de handover).
-- Cada activo digital ahora define en su catálogo si al offboarding se
-- desactiva de inmediato o después de N días; la fila por empleado guarda
-- desde cuándo ya se puede solicitar esa revocación.

-- 1. Modo de offboarding configurado por tipo de activo digital.
alter table company_assets
  add column if not exists offboarding_modo text not null default 'inmediato'
    check (offboarding_modo in ('inmediato', 'gracia')),
  add column if not exists offboarding_gracia_dias int;

-- 2. Desde cuándo se puede solicitar la revocación para un empleado dado.
--    Null = ya se puede solicitar (offboarding inmediato o sin definir).
alter table employee_digital_assets
  add column if not exists revocar_disponible_at timestamptz;
