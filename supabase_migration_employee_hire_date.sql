-- Migración: fecha de ingreso a la empresa por empleado.
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: no había forma de registrar cuándo entró un empleado a la
-- empresa, ni de detectar fácilmente los ingresos nuevos o próximos desde
-- app/empleados.html (formulario individual, carga masiva, y la tabla de
-- empleados con el badge de "Nuevo" / "Próximo ingreso").

alter table company_employees add column if not exists hire_date date;
