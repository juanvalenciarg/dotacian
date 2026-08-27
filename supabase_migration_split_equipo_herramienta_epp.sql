-- Migración: dividir "Herramientas / EPP" (tipo 'equipo') en dos
-- subcategorías separadas: 'herramienta' (Kit de herramientas, Radio de
-- comunicación) y 'epp' (Casco, Zapatos de seguridad, Equipo para trabajo
-- en alturas, Gafas de protección, Guantes de seguridad, Chaleco
-- reflectivo, Protección auditiva, Respirador/Mascarilla, Lámpara de
-- casco). EPP es lo exigido por ley según la industria; Herramientas es
-- equipo de trabajo general (carritos de aseo, cajas de herramientas,
-- radios, maquinaria).
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu),
-- DESPUÉS de desplegar el código que ya usa las claves 'herramienta'/'epp'
-- (app/activos.html, app/roles.html, assets/js/i18n.js).

-- 1. company_assets: los activos que cada empresa activó, uno por fila.
update company_assets
set tipo = 'herramienta'
where tipo = 'equipo'
  and nombre in ('Kit de herramientas', 'Radio de comunicación', 'Tool kit', 'Two-way radio');

update company_assets
set tipo = 'epp'
where tipo = 'equipo';

-- 2. role_definition.items: array jsonb de ítems por rol. Cada elemento
-- trae {name, category, tipo, qty, specs}; solo se reescribe el campo
-- 'tipo' de los elementos que tenían 'equipo', preservando todo lo demás.
update role_definition
set items = (
  select coalesce(jsonb_agg(
    case
      when elem->>'tipo' = 'equipo'
        and elem->>'name' in ('Kit de herramientas', 'Radio de comunicación', 'Tool kit', 'Two-way radio')
        then jsonb_set(elem, '{tipo}', '"herramienta"')
      when elem->>'tipo' = 'equipo'
        then jsonb_set(elem, '{tipo}', '"epp"')
      else elem
    end
  ), '[]'::jsonb)
  from jsonb_array_elements(items) as elem
)
where items is not null
  and jsonb_typeof(items) = 'array'
  and exists (
    select 1 from jsonb_array_elements(items) e where e->>'tipo' = 'equipo'
  );
