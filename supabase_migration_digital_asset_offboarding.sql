-- Migración: revocación de activos digitales en offboarding
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
-- Requiere haber corrido antes supabase_migration_digital_asset_activation.sql.
--
-- Contexto: al dar de baja o desactivar un empleado, hoy no pasa nada con sus
-- accesos digitales ya solicitados/activados (VPN, correo, licencias). Se
-- agregan dos estados nuevos al mismo ciclo de vida de employee_digital_assets
-- para poder solicitar la revocación por correo, igual que se solicita la
-- activación.

-- 1. Ampliar el check de status con los estados de revocación.
alter table employee_digital_assets
  drop constraint if exists employee_digital_assets_status_check;

alter table employee_digital_assets
  add constraint employee_digital_assets_status_check
  check (status in ('pendiente', 'solicitado', 'activado', 'revocacion_solicitada', 'revocado'));

-- 2. Columnas de seguimiento para la revocación.
alter table employee_digital_assets
  add column if not exists revocacion_solicitada_at timestamptz,
  add column if not exists revocado_at timestamptz;
