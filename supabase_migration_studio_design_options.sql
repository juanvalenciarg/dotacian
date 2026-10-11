-- Migración: opciones de las prendas configurables en Dotacian Studio
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: la camisa y la bata se arman por partes en /app/uniformes/studio.
-- Cada diseño guarda lo que eligió el cliente:
--   { "cuello": "camisero|mao|polo|redondo",
--     "manga": "corta|larga",
--     "cierre": "botones|cremallera|ninguno",
--     "bolsillos": "ninguno|pecho|inferiores|ambos",
--     "zonas": { "cuello": <color>, "puno": <color>, "detalle": <color> } }
-- Los colores son claves de la paleta (ej. "vinotinto") o un HEX "#RRGGBB";
-- null en una zona = mismo color del cuerpo. studio_designs.color también
-- puede ser un HEX personalizado.
-- Las demás prendas dejan opciones en null.

alter table studio_designs add column if not exists opciones jsonb;
