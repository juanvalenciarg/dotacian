/* ==========================================================================
   DotacIAn — Home agéntico (/app/home)
   Barra de chat para empezar a diseñar uniformes. Entiende el pedido
   (prenda, color, rol, cantidad, logo e intención), responde y propone
   acciones que llevan al usuario a Studio, Cotizaciones, Roles, etc.
   La respuesta conversacional viene de la Edge Function `dot-chat`; si falla,
   se usa una respuesta local.
   ========================================================================== */
(function () {
  const form = document.getElementById('agent-form');
  if (!form) return;
  const input = document.getElementById('agent-input');
  const sendBtn = document.getElementById('agent-send');
  const thread = document.getElementById('agent-thread');
  const agent = document.getElementById('agent');
  const STORE_KEY = 'dotacian_agent_thread_v1';

  const norm = (s) => String(s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
  const esc = (s) => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const cap = (s) => s.charAt(0).toUpperCase() + s.slice(1);

  // Prendas que Studio puede abrir (claves de GARMENTS con foto en app/studio.html)
  const STUDIO_GARMENTS = [
    { key: 'camisa_aseo', label: 'Camisa antifluido para aseo', re: /\bcamisas?\b.*\b(aseo|antifluidos?|limpieza|servicios generales)\b|\bantifluidos?\b.*\b(aseo|limpieza|servicios generales)\b/ },
    { key: 'polo', label: 'Camiseta tipo polo', re: /\bpolos?\b|tipo polo|camibusos?/ },
    { key: 'camiseta', label: 'Camiseta', re: /\bcamisetas?\b|\bplayeras?\b|t-?shirts?|\bremeras?\b/ },
    { key: 'camisa', label: 'Camisa', re: /\bcamisas?\b|oxford/ },
    { key: 'hoodie', label: 'Hoodie', re: /hoodies?|sudaderas?|buzos? con capota|chaquetas? con capota|\bcanguros?\b/ },
  ];
  // Prendas que se cotizan aunque todavía no estén en Studio
  const OTHER_GARMENTS = [
    { label: 'Overol', re: /overol(es)?|\bmamelucos?\b|\bbragas?\b/ },
    { label: 'Antifluido', re: /antifluidos?|scrubs?|pijamas? quirurgic|uniformes? medic/ },
    { label: 'Chaqueta de chef', re: /chaquetas? de (chef|cocina)|filipinas?|\bchef\b/ },
    { label: 'Delantal', re: /delantal(es)?|mandil(es)?/ },
    { label: 'Pantalón', re: /pantalon(es)?|jeans?/ },
    { label: 'Bata', re: /\bbatas?\b/ },
    { label: 'Chaleco', re: /chalecos?/ },
    { label: 'Calzado', re: /botas?|zapatos?|calzado|tenis/ },
    { label: 'EPP', re: /\bepp\b|cascos?|guantes?|gafas|tapabocas|proteccion personal/ },
    { label: 'Gorra', re: /gorras?|cofias?|gorros?/ },
  ];
  // Colores de Studio (claves de SHIRT_COLORS). Los compuestos van primero.
  const COLORS = [
    ['azulMarino', 'Azul marino', '#1F2A44', /azul marino|azul oscuro|\bnavy\b/],
    ['azulRey', 'Azul rey', '#2A56C6', /azul rey|azul real/],
    ['azulPetroleo', 'Azul petróleo', '#1E4D5C', /azul petroleo/],
    ['verdeLima', 'Verde lima', '#9CC53F', /verde lima/],
    ['verdeBotella', 'Verde botella', '#1E3D2C', /verde botella/],
    ['verdeOliva', 'Verde oliva', '#5C5E36', /verde oliva|verde militar/],
    ['menta', 'Verde menta', '#7CC6A4', /menta/],
    ['grisClaro', 'Gris claro', '#A7ACB3', /gris claro/],
    ['grafito', 'Gris grafito', '#3C4049', /grafito|gris oscuro/],
    ['vinotinto', 'Vinotinto', '#7A1E2C', /vinotinto|vino tinto|burdeos|guinda|\bvino\b/],
    ['celeste', 'Celeste', '#8EC5E6', /celeste|azul cielo|azul claro/],
    ['azul', 'Azul', '#1E3F8A', /\bazul(es)?\b/],
    ['negro', 'Negro', '#1B1B1E', /\bnegr[oa]s?\b/],
    ['blanco', 'Blanco', '#F4F4F1', /\bblanc[oa]s?\b/],
    ['rojo', 'Rojo', '#B4232C', /\broj[oa]s?\b/],
    ['beige', 'Beige', '#C8B48E', /beige|caqui|kaki|khaki/],
    ['gris', 'Gris', '#5E646E', /\bgris(es)?\b/],
    ['verde', 'Verde', '#2F6B4F', /\bverdes?\b/],
    ['turquesa', 'Turquesa', '#1C9AA0', /turquesa/],
    ['naranja', 'Naranja', '#E26A2C', /naranja/],
    ['amarillo', 'Amarillo', '#E8B930', /amarill[oa]s?/],
    ['morado', 'Morado', '#5B3E8E', /morad[oa]s?|lila|purpura/],
    ['rosado', 'Rosado', '#E79BB5', /rosad[oa]s?|\brosas?\b/],
    ['cafe', 'Café', '#6A4A35', /\bcafe\b|marron/],
    ['hueso', 'Hueso', '#E8E0CC', /hueso|crema/],
  ];

  const ROLE_STOP = /^(la|el|los|las|mi|mis|nuestro|nuestra|nuestros|nuestras|todo|toda|todos|todas|un|una|unos|unas|mi empresa|la empresa|empresa|que|cada)$/;

  function parse(text, extraKeywords) {
    const raw = String(text || '');
    const t = norm(raw + ' ' + (extraKeywords || []).join(' '));
    const studio = STUDIO_GARMENTS.find(g => g.re.test(t)) || null;
    // La camisa antifluido de aseo sí está en Studio: no se repite como prenda por cotizar.
    const others = OTHER_GARMENTS.filter(g => g.re.test(t) && !(studio && studio.key === 'camisa_aseo' && g.label === 'Antifluido')).map(g => g.label);
    const color = COLORS.find(c => c[3].test(t));

    let qty = null;
    const q = norm(raw).match(/\b(\d{1,5})\s*(personas?|empleados?|colaboradores?|trabajadores?|operari[oa]s?|uniformes?|unidades|uds|prendas|piezas|[a-z]+)?/);
    if (q && +q[1] > 0) qty = +q[1];

    let role = null;
    // Se busca sobre el texto original (en minúsculas) para conservar las tildes.
    const r = raw.toLowerCase().match(/(?:^|\s)para\s+(?:los|las|mis|nuestros|nuestras|el|la|mi|nuestro|nuestra|todo el|todos los|todas las)?\s*(?:\d+\s+)?(?:equipo de\s+|área de\s+|area de\s+|personal de\s+)?([a-záéíóúüñ ]{3,32}?)(?=\s*(?:[,.;!?]|\sde\s|\scon\s|\sen\s|\sque\s|\sy\s|$))/);
    if (r) {
      const cand = r[1].trim();
      if (cand && !ROLE_STOP.test(norm(cand)) && !/empresa|negocio|compania/.test(norm(cand))) role = cap(cand);
    }

    return {
      studio: studio ? { key: studio.key, label: studio.label } : null,
      others,
      color: color ? { key: color[0], label: color[1], hex: color[2] } : null,
      qty,
      role,
      logo: /logo|marca|bordad|estampad|personalizad/.test(t),
      intents: {
        quote: /cotiz|precio|costo|cuanto (cuesta|vale|sale)|presupuesto/.test(t),
        roles: /\broles?\b|cargos?\b|\bkits?\b/.test(t),
        employees: /emplead|nomina|plantilla|tallas de|colaboradores/.test(t),
        orders: /pedido|envio|entrega|rastre|seguimiento|llega/.test(t),
        stock: /bodega|stock|inventario|existencia/.test(t),
        catalog: /mis uniformes|catalogo|disenos guardados|mis disenos/.test(t),
      },
    };
  }

  const ICONS = {
    studio: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.38 3.46 16 2a4 4 0 0 1-8 0L3.62 3.46a2 2 0 0 0-1.34 2.23l.58 3.47a1 1 0 0 0 .99.84H6v10c0 1.1.9 2 2 2h8a2 2 0 0 0 2-2V10h2.15a1 1 0 0 0 .99-.84l.58-3.47a2 2 0 0 0-1.34-2.23z"/></svg>',
    quote: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/><line x1="8" y1="13" x2="16" y2="13"/><line x1="8" y1="17" x2="13" y2="17"/></svg>',
    roles: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>',
    employees: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>',
    orders: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="3" width="15" height="13"/><polygon points="16 8 20 8 23 11 23 16 16 16 16 8"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/></svg>',
    stock: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="21 8 21 21 3 21 3 8"/><rect x="1" y="3" width="22" height="5"/><line x1="10" y1="12" x2="14" y2="12"/></svg>',
    catalog: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/></svg>',
  };

  function buildActions(p) {
    const a = [];
    if (p.studio) {
      const qs = new URLSearchParams({ prenda: p.studio.key });
      if (p.color) qs.set('color', p.color.key);
      a.push({ primary: true, icon: 'studio', title: 'Diseñar en Studio', sub: [p.studio.label, p.color && p.color.label].filter(Boolean).join(' · '), href: '/app/studio?' + qs });
    }
    if (p.others.length || p.intents.quote || (p.studio && p.qty)) {
      const what = p.others.length ? p.others.join(', ') : (p.qty ? `${p.qty} prendas` : 'Precio por talla y sede');
      a.push({ primary: !p.studio, icon: 'quote', title: 'Solicitar cotización', sub: what, href: '/app/cotizaciones' });
    }
    if (p.role || p.intents.roles) a.push({ icon: 'roles', title: p.role ? `Crear rol «${p.role}»` : 'Configurar roles', sub: 'Kit de prendas por cargo', href: '/app/roles' });
    if (p.intents.employees) a.push({ icon: 'employees', title: 'Cargar empleados', sub: 'Plantilla y tallas', href: '/app/empleados' });
    if (p.intents.orders) a.push({ icon: 'orders', title: 'Ver pedidos', sub: 'Estado de producción y envío', href: '/app/pedidos' });
    if (p.intents.stock) a.push({ icon: 'stock', title: 'Ver bodega', sub: 'Stock por prenda y talla', href: '/app/bodega' });
    if (p.intents.catalog) a.push({ icon: 'catalog', title: 'Mis uniformes', sub: 'Diseños guardados', href: '/app/uniformes' });
    if (!a.length) {
      a.push({ primary: true, icon: 'studio', title: 'Empezar en Studio', sub: 'Elige prenda, color y logo', href: '/app/studio' });
      a.push({ icon: 'quote', title: 'Solicitar cotización', sub: 'Cuéntanos qué necesitas', href: '/app/cotizaciones' });
      a.push({ icon: 'catalog', title: 'Mis uniformes', sub: 'Diseños guardados', href: '/app/uniformes' });
    }
    return a.slice(0, 4);
  }

  function localReply(p) {
    if (p.studio) {
      const parts = [`**${p.studio.label}**`];
      if (p.color) parts.push(`en ${p.color.label.toLowerCase()}`);
      if (p.logo) parts.push('con tu logo');
      if (p.role) parts.push(`para ${p.role.toLowerCase()}`);
      let msg = `¡Listo! Preparé ${parts.join(' ')}. Ábrelo en Studio para ver cómo queda y ajustar detalles.`;
      if (!p.color) msg += ' Aún no me dijiste el color; puedes elegirlo allí.';
      if (p.qty) msg += ` Cuando lo apruebes, cotizamos las ${p.qty} unidades.`;
      return msg;
    }
    if (p.others.length) {
      return `Entendido: ${p.others.join(', ').toLowerCase()}. Estas prendas las fabricamos a la medida; envía la solicitud de cotización y te respondemos con precios por talla.`;
    }
    if (Object.values(p.intents).some(Boolean)) return 'Claro, te llevo a donde puedes hacerlo:';
    return 'Cuéntame un poco más: ¿qué prenda necesitas, de qué color, para qué rol y para cuántas personas? Mientras tanto, puedes empezar por aquí:';
  }

  function briefHtml(p) {
    const items = [];
    if (p.studio) items.push(`Prenda: ${esc(p.studio.label)}`);
    p.others.forEach(o => items.push(`Prenda: ${esc(o)}`));
    if (p.color) items.push(`<i style="background:${p.color.hex}"></i>${esc(p.color.label)}`);
    if (p.role) items.push(`Rol: ${esc(p.role)}`);
    if (p.qty) items.push(`${p.qty} unidades`);
    if (p.logo) items.push('Con logo');
    return items.length ? `<div class="brief">${items.map(i => `<span>${i}</span>`).join('')}</div>` : '';
  }

  function mdToHtml(text) {
    const src = String(text || '');
    if (window.marked && window.DOMPurify) {
      try { return DOMPurify.sanitize(marked.parse(src)); } catch (e) { /* sigue abajo */ }
    }
    return '<p>' + esc(src).replace(/\*\*(.+?)\*\*/g, '<b>$1</b>').replace(/\n/g, '<br>') + '</p>';
  }

  const SPARK = '<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l1.9 5.8L20 10l-6.1 2.2L12 18l-1.9-5.8L4 10l6.1-2.2z"/></svg>';

  function renderUser(text) {
    const el = document.createElement('div');
    el.className = 'msg user';
    el.innerHTML = `<div class="bubble">${esc(text)}</div>`;
    thread.appendChild(el);
    return el;
  }

  function renderTyping() {
    const el = document.createElement('div');
    el.className = 'msg ai';
    el.innerHTML = `<span class="av">${SPARK}</span><div class="bubble"><span class="typing" aria-label="DotacIAn está pensando"><span></span><span></span><span></span></span></div>`;
    thread.appendChild(el);
    return el;
  }

  function renderAi(el, message, parsed) {
    const actions = buildActions(parsed);
    el.innerHTML = `<span class="av">${SPARK}</span><div class="bubble">${mdToHtml(message)}${briefHtml(parsed)}<div class="actions">${actions.map(a => `
      <a class="action${a.primary ? ' primary' : ''}" href="${esc(a.href)}">
        <span class="ic">${ICONS[a.icon]}</span><span><b>${esc(a.title)}</b><small>${esc(a.sub || '')}</small></span>
      </a>`).join('')}</div></div>`;
  }

  // Contexto de negocio que acompaña cada mensaje, para que el agente responda
  // como Dotacian (fabricante + plataforma) y no como un buscador de proveedores.
  const DOTACIAN_CONTEXT = [
    'Eres DotacIAn, el asistente de inteligencia artificial de Dotacian dentro de su plataforma.',
    'Dotacian es la primera WorkwearTech de LATAM: una empresa todo en uno que fabrica uniformes empresariales y ofrece la plataforma para gestionarlos.',
    'El cliente diseña el 100% de su uniforme en Dotacian Studio (prenda, color, cortes, detalles y su logo), solicita la cotización en la plataforma, y Dotacian lo fabrica, lo entrega a cada empleado con firma digital y le ayuda a controlar tallas, stock, renovaciones y gasto.',
    'Dotacian diseña y fabrica todo: nunca sugieras buscar otros proveedores, tiendas, fabricantes o compras en línea.',
    'Responde en español, en máximo 3 frases, con tono cálido y concreto. Si falta información, pregunta por prenda, color, rol, cantidad o tallas.',
    'Debajo de tu respuesta la plataforma muestra botones de acción (diseñar en Studio, cotizar, crear rol), así que no inventes enlaces ni precios.',
  ].join(' ');

  function buildPrompt(text) {
    const prev = history.slice(0, -1).slice(-6)
      .map(m => (m.role === 'user' ? 'Cliente: ' + m.text : 'DotacIAn: ' + String(m.message || '').slice(0, 300)))
      .join('\n');
    return `[Contexto (no lo repitas al cliente)]\n${DOTACIAN_CONTEXT}\n` +
      (prev ? `\n[Conversación previa]\n${prev}\n` : '') +
      `\n[Mensaje del cliente]\n${text}`;
  }

  // Si el agente responde fuera del modelo de Dotacian (resultados de catálogo
  // que aquí no mostramos, o mandar a buscar otros proveedores), se usa la respuesta local.
  function usableAiMessage(m) {
    if (!m || typeof m !== 'string') return null;
    const n = norm(m);
    if (/encontre|estas opciones|en el catalogo|resultados/.test(n)) return null;
    if (/proveedor|en linea|tiendas?\b|fabricantes?|mercado ?libre|amazon|otras empresas/.test(n)) return null;
    return m.trim().slice(0, 1200);
  }

  async function askDot(text) {
    const client = window._supabase;
    if (!client || !client.functions) return {};
    try {
      const timeout = new Promise(res => setTimeout(() => res({ timeout: true }), 12000));
      // `text` lleva el contexto + el mensaje; `context` y `message` van aparte
      // por si la función los lee directamente.
      const call = client.functions.invoke('dot-chat', { body: { text: buildPrompt(text), message: text, context: DOTACIAN_CONTEXT } });
      const r = await Promise.race([call, timeout]);
      if (!r || r.timeout || r.error || !r.data) return {};
      return { message: r.data.message, keywords: Array.isArray(r.data.keywords) ? r.data.keywords : [] };
    } catch (e) {
      console.warn('dot-chat no disponible:', e);
      return {};
    }
  }

  // ---------- Persistencia de la conversación (pestaña actual) ----------
  let history = [];
  function save() { try { sessionStorage.setItem(STORE_KEY, JSON.stringify(history.slice(-20))); } catch (e) { /* sin storage */ } }
  function restore() {
    let saved = [];
    try { saved = JSON.parse(sessionStorage.getItem(STORE_KEY) || '[]'); } catch (e) { saved = []; }
    if (!Array.isArray(saved) || !saved.length) return;
    history = saved;
    agent.classList.add('started');
    saved.forEach(m => {
      if (m.role === 'user') renderUser(m.text);
      else { const el = document.createElement('div'); el.className = 'msg ai'; thread.appendChild(el); renderAi(el, m.message, m.parsed); }
    });
  }

  // Lo que el cliente ya dijo en mensajes anteriores (prenda, color, rol,
  // cantidad, logo) se conserva si el mensaje nuevo no lo cambia.
  function mergeWithPrevious(p) {
    const last = [...history].reverse().find(m => m.role === 'ai' && m.parsed);
    if (!last) return p;
    const q = last.parsed;
    return {
      ...p,
      studio: p.studio || (p.others.length ? null : q.studio),
      others: p.others.length || p.studio ? p.others : (q.others || []),
      color: p.color || q.color,
      role: p.role || q.role,
      qty: p.qty || q.qty,
      logo: p.logo || q.logo,
    };
  }

  let busy = false;
  async function send(text) {
    text = String(text || '').trim();
    if (!text || busy) return;
    busy = true;
    agent.classList.add('started');
    input.value = '';
    autosize();
    renderUser(text);
    history.push({ role: 'user', text });
    const typing = renderTyping();
    typing.scrollIntoView({ behavior: 'smooth', block: 'nearest' });

    const dot = await askDot(text);
    // Solo el mensaje del cliente decide prenda/color/rol: las palabras clave del
    // agente ahora salen también del contexto y podrían confundir la detección.
    const parsed = mergeWithPrevious(parse(text));
    const message = usableAiMessage(dot.message) || localReply(parsed);
    renderAi(typing, message, parsed);
    history.push({ role: 'ai', message, parsed });
    save();
    if (typeof gtag === 'function') gtag('event', 'agent_prompt', { has_garment: !!parsed.studio });
    busy = false;
    syncBtn();
    input.focus();
  }

  function autosize() {
    input.style.height = 'auto';
    input.style.height = Math.min(input.scrollHeight, 200) + 'px';
  }
  function syncBtn() {
    sendBtn.disabled = busy || !input.value.trim();
    const nb = document.getElementById('agent-new');
    if (nb) nb.disabled = busy;
  }

  input.addEventListener('input', () => { autosize(); syncBtn(); });
  input.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey && !e.isComposing) { e.preventDefault(); send(input.value); }
  });
  form.addEventListener('submit', (e) => { e.preventDefault(); send(input.value); });

  // ---------- Nueva conversación ----------
  const newBtn = document.getElementById('agent-new');
  function newConversation() {
    if (busy) return;
    history = [];
    try { sessionStorage.removeItem(STORE_KEY); } catch (e) { /* sin storage */ }
    thread.innerHTML = '';
    agent.classList.remove('started');
    input.value = '';
    autosize();
    syncBtn();
    window.scrollTo({ top: 0, behavior: 'smooth' });
    input.focus();
  }
  if (newBtn) newBtn.addEventListener('click', newConversation);

  // dashboard.html llama a updateDotPrompts(company.industry); ya no hay sugerencias rápidas.
  window.updateDotPrompts = function () {};

  restore();
  syncBtn();
  if (!history.length && window.matchMedia('(min-width: 769px)').matches) input.focus();
})();
