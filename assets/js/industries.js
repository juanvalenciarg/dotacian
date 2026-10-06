// Lista oficial de industrias de Dotacian. La clave es lo que se guarda en
// company_profile.industry; DS Hub (admin) habilita prendas por
// esta misma clave (tabla studio_garment_industries). Si se agrega una
// industria aquí, también hay que sumarla al check de esa tabla.
window.DOTACIAN_INDUSTRIES = [
  { key: 'restaurantes', label: 'Restaurantes' },
  { key: 'limpieza', label: 'Limpieza' },
  { key: 'industrial', label: 'Industrial' },
  { key: 'corporate', label: 'Corporativo' },
  { key: 'seguridad', label: 'Seguridad' },
  { key: 'hoteleria', label: 'Hotelería' },
  { key: 'retail', label: 'Retail' },
  { key: 'salud', label: 'Salud' },
  { key: 'construccion', label: 'Construcción' },
  { key: 'logistica', label: 'Logística' }
];

window.industryLabel = function (key) {
  const k = String(key || '').trim().toLowerCase();
  const found = window.DOTACIAN_INDUSTRIES.find(i => i.key === k);
  return found ? found.label : null;
};

// Llena un <select> con las industrias. Si el valor actual no está en la
// lista (datos viejos en texto libre), se agrega como opción "sin clasificar"
// para no perderlo de vista hasta que se corrija.
window.fillIndustrySelect = function (select, currentValue, placeholder) {
  if (!select) return;
  const current = String(currentValue || '').trim();
  const known = window.industryLabel(current);
  let html = `<option value="">${placeholder || 'Selecciona una industria...'}</option>`;
  if (current && !known) {
    html += `<option value="${current.replace(/"/g, '&quot;')}">${current.replace(/</g, '&lt;')} (sin clasificar)</option>`;
  }
  html += window.DOTACIAN_INDUSTRIES.map(i => `<option value="${i.key}">${i.label}</option>`).join('');
  select.innerHTML = html;
  select.value = known ? current.toLowerCase() : current;
};
