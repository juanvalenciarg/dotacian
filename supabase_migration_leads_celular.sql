-- Migración: celular opcional en los leads del formulario de la landing
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: el formulario de index.html / index.en.html ahora tiene un campo
-- "Celular (opcional)". Se guarda en esta columna y se muestra en la tarjeta
-- del lead en admin.leads.html. Es texto libre porque llegan números de
-- México y Colombia con distintos formatos.

alter table public.leads_dotacian
  add column if not exists celular text;
