// Imágenes (PNG) de las prendas de Dotacian Studio para el panel admin.
// Carga un solo visor 3D oculto (/app/studio.html?embed=1) y le pide una foto
// de cada prenda, en vez de abrir un visor por tarjeta (con muchas prendas el
// navegador no soporta tantos visores). Las fotos se guardan en sessionStorage.
(function () {
  // Cambia este valor cuando cambien los modelos 3D para regenerar las imágenes.
  const RENDER_VERSION = '3';
  const cache = {};
  let frame = null;
  let studioPromise = null;
  let queue = Promise.resolve();

  function cacheKey(key, color) {
    return `ds-render-${RENDER_VERSION}-${key}-${color}`;
  }

  function readCache(key, color) {
    const k = cacheKey(key, color);
    if (cache[k]) return cache[k];
    try {
      const v = sessionStorage.getItem(k);
      if (v) cache[k] = v;
      return v;
    } catch (e) {
      return null;
    }
  }

  function writeCache(key, color, url) {
    const k = cacheKey(key, color);
    cache[k] = url;
    try { sessionStorage.setItem(k, url); } catch (e) { /* sin espacio: se regenera después */ }
  }

  function loadStudio() {
    if (studioPromise) return studioPromise;
    studioPromise = new Promise((resolve, reject) => {
      frame = document.createElement('iframe');
      frame.setAttribute('aria-hidden', 'true');
      frame.tabIndex = -1;
      frame.title = '';
      frame.style.cssText = 'position: fixed; left: -10000px; top: 0; width: 520px; height: 520px; border: 0; pointer-events: none;';
      frame.src = '/app/studio.html?embed=1';
      document.body.appendChild(frame);
      const start = Date.now();
      const check = () => {
        let studio = null;
        try { studio = frame.contentWindow && frame.contentWindow.dotacianStudio; } catch (e) { /* cargando */ }
        if (studio && studio.snapshot) return resolve(studio);
        if (Date.now() - start > 25000) return reject(new Error('El visor 3D no cargó'));
        setTimeout(check, 200);
      };
      check();
    });
    studioPromise.catch(() => { studioPromise = null; });
    return studioPromise;
  }

  // Devuelve (promesa) el dataURL de la prenda. Las fotos se generan en fila,
  // una a la vez, sobre el mismo visor.
  function getRender(key, color = 'blanco') {
    const cached = readCache(key, color);
    if (cached) return Promise.resolve(cached);
    const job = queue.then(async () => {
      const again = readCache(key, color);
      if (again) return again;
      const studio = await loadStudio();
      const url = studio.snapshot(key, color);
      if (url) writeCache(key, color, url);
      await new Promise(r => setTimeout(r, 20));
      return url;
    });
    queue = job.catch(() => null);
    return job;
  }

  // Llena un contenedor con la imagen de la prenda (o un indicador de carga).
  function fillRender(el, key, color = 'blanco') {
    if (!el) return;
    const cached = readCache(key, color);
    if (cached) {
      el.innerHTML = `<img src="${cached}" alt="">`;
      return;
    }
    el.innerHTML = '<span class="ds-render-loading" aria-label="Generando imagen"></span>';
    getRender(key, color)
      .then(url => { if (url) el.innerHTML = `<img src="${url}" alt="">`; })
      .catch(() => { el.innerHTML = '<span class="ds-render-missing">Vista no disponible</span>'; });
  }

  window.DSRenders = { getRender, fillRender, readCache };
})();
