-- Migración: historial de vistas del blog (una fila por visita)
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: hasta hoy cada artículo solo guarda dos contadores
-- (blog_posts.views_total / views_unique), sin fecha, así que no se puede
-- graficar la evolución en el tiempo. articulo.html ahora registra además una
-- fila por visita en esta tabla y admin.blog.html la usa para la gráfica
-- "Vistas en el tiempo". El historial empieza desde que se publica el cambio:
-- no hay forma de reconstruir las visitas anteriores.

create table if not exists public.blog_post_views (
  id bigint generated always as identity primary key,
  post_id uuid not null references public.blog_posts(id) on delete cascade,
  viewed_at timestamptz not null default now(),
  is_unique boolean not null default false
);

create index if not exists blog_post_views_viewed_at_idx
  on public.blog_post_views (viewed_at);
create index if not exists blog_post_views_post_id_viewed_at_idx
  on public.blog_post_views (post_id, viewed_at);

alter table public.blog_post_views enable row level security;

-- Cualquier visitante del sitio puede registrar una vista (igual que los
-- contadores de blog_posts); solo admins pueden leer el historial.
drop policy if exists "blog_post_views_insert_public" on public.blog_post_views;
create policy "blog_post_views_insert_public" on public.blog_post_views
  for insert to anon, authenticated
  with check (true);

drop policy if exists "blog_post_views_select_admin" on public.blog_post_views;
create policy "blog_post_views_select_admin" on public.blog_post_views
  for select to authenticated
  using (exists (select 1 from public.admin_profile a where a.id = auth.uid()));
