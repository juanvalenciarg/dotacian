#!/usr/bin/env python3
"""Regenera sitemap.xml con las páginas públicas y todos los artículos del blog.

Uso (desde la carpeta del proyecto):
    python3 tools/generar_sitemap.py

Ejecútalo cada vez que publiques o borres un artículo, y luego haz commit de
sitemap.xml. Lee los artículos de Supabase con la clave pública del sitio.
"""
import json
import os
import urllib.request
from xml.sax.saxutils import escape

SITE = 'https://www.dotacian.com'
SUPABASE_URL = 'https://awuhvewotmwelurmjvmu.supabase.co'
SUPABASE_ANON_KEY = 'sb_publishable_4WG86Fal8RQ3tV0sNXZIow_hikHt0Aq'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'sitemap.xml')

# Páginas públicas con su par de idioma (es, en).
PAGES = [
    ('/', '/index.en.html', '1.0'),
    ('/blog.es.html', '/blog.html', '0.8'),
]


def fetch_posts():
    url = f'{SUPABASE_URL}/rest/v1/blog_posts?select=slug,lang,created_at,translation_group_id&order=created_at.desc'
    req = urllib.request.Request(url, headers={'apikey': SUPABASE_ANON_KEY, 'Authorization': f'Bearer {SUPABASE_ANON_KEY}'})
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.load(r)


def alt_links(versions):
    lines = [f'    <xhtml:link rel="alternate" hreflang="{lang}" href="{escape(href)}"/>' for lang, href in versions]
    if len(versions) > 1:
        default = dict(versions).get('es', versions[0][1])
        lines.append(f'    <xhtml:link rel="alternate" hreflang="x-default" href="{escape(default)}"/>')
    return lines


def url_entry(loc, versions, lastmod=None, priority=None):
    out = ['  <url>', f'    <loc>{escape(loc)}</loc>']
    if lastmod:
        out.append(f'    <lastmod>{lastmod}</lastmod>')
    if priority:
        out.append(f'    <priority>{priority}</priority>')
    out += alt_links(versions) if len(versions) > 1 else []
    out.append('  </url>')
    return out


def main():
    posts = fetch_posts()
    lines = ['<?xml version="1.0" encoding="UTF-8"?>',
             '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">']

    for es, en, prio in PAGES:
        versions = [('es', SITE + es), ('en', SITE + en)]
        for loc in (SITE + es, SITE + en):
            lines += url_entry(loc, versions, priority=prio)

    groups = {}
    for p in posts:
        groups.setdefault(p.get('translation_group_id') or p['slug'], []).append(p)
    for p in posts:
        group = groups[p.get('translation_group_id') or p['slug']]
        versions = [('en' if g['lang'] == 'en' else 'es', f"{SITE}/articulo.html?slug={g['slug']}") for g in group]
        loc = f"{SITE}/articulo.html?slug={p['slug']}"
        lines += url_entry(loc, versions, lastmod=(p.get('created_at') or '')[:10] or None, priority='0.7')

    lines.append('</urlset>')
    with open(OUT, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')
    print(f'sitemap.xml: {len(PAGES) * 2} páginas + {len(posts)} artículos')


if __name__ == '__main__':
    main()
