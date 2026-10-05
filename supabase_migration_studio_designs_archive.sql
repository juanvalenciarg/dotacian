-- Migración: archivar diseños de Dotacian Studio en lugar de borrarlos
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: los diseños se pueden asignar a roles (role_definition.items[].design_id).
-- Al "eliminar" un diseño se quita de los roles, pero el registro y su logo se
-- conservan para el histórico (entregas ya hechas). archived_at marca el
-- diseño como eliminado para la lista del Studio y los selectores de Roles.

alter table studio_designs
  add column if not exists archived_at timestamptz;
