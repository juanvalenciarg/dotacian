function showToast(title, message, type = 'success') {
  let container = document.querySelector('.toast-container');
  if (!container) {
    container = document.createElement('div');
    container.className = 'toast-container';
    document.body.appendChild(container);
  }

  const toast = document.createElement('div');
  toast.className = `toast ${type === 'error' ? 'toast-error' : ''}`;

  const icon = type === 'success'
    ? `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>`
    : `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>`;

  toast.innerHTML = `
    <div class="toast-icon">${icon}</div>
    <div class="toast-content">
      <div class="toast-title">${title}</div>
      <div class="toast-message">${message}</div>
    </div>
    <button class="toast-close" onclick="this.parentElement.remove()">✕</button>
  `;

  container.appendChild(toast);

  setTimeout(() => {
    if (toast.parentElement) {
      toast.style.animation = 'toastSlideOut 0.4s ease-in forwards';
      setTimeout(() => toast.remove(), 400);
    }
  }, 4000);
}

function updateVersionIndicator(country) {
  const container = document.getElementById('version-tag');
  if (!container) return;
  
  const isColombia = country === 'CO' || country === 'Colombia';
  const flagUrl = isColombia 
    ? 'https://flagcdn.com/w40/co.png' 
    : 'https://flagcdn.com/w40/mx.png';
  
  container.innerHTML = `
    <div class="version-indicator">
      <div class="flag-circle" title="Versión ${isColombia ? 'Colombia' : 'México'}">
        <img src="${flagUrl}" alt="Flag">
      </div>
    </div>
  `;
  
  // Store for other pages
  localStorage.setItem('dotacian_user_country', country);
}

function initVersionIndicator() {
  const country = localStorage.getItem('dotacian_user_country');
  if (country) {
    updateVersionIndicator(country);
  }
}

// Auto-init on load if country is known
function initSidebar() {
  const groups = document.querySelectorAll('.nav-group');
  groups.forEach(group => {
    const mainItem = group.querySelector('.nav-item');
    if (mainItem) {
      mainItem.addEventListener('click', (e) => {
        // Only toggle if it has sub-items
        const subItems = group.querySelector('.nav-sub-items');
        if (subItems) {
          e.preventDefault();
          e.stopPropagation();
          group.classList.toggle('active-group');
          
          // Rotate arrow icon if exists
          const arrow = mainItem.querySelector('span:last-child svg');
          if (arrow) {
            arrow.style.transform = group.classList.contains('active-group') ? 'rotate(180deg)' : 'rotate(0deg)';
            arrow.style.transition = 'transform 0.3s ease';
          }
        }
      });
    }
  });
}

// Reorganiza la cabecera en móviles para que luzca como en cotizaciones
function alignMobileHeader() {
  const appHeader = document.querySelector('.app-header');
  const welcomeBanner = document.querySelector('.welcome-banner');
  if (!appHeader || !welcomeBanner) return;

  const headerRight = document.querySelector('.header-right');
  const toggleBtn = document.querySelector('.mobile-menu-toggle');

  if (window.innerWidth <= 992) {
    if (headerRight && headerRight.parentElement === appHeader) {
      welcomeBanner.appendChild(headerRight);
      headerRight.style.position = 'relative';
      headerRight.style.marginTop = '1rem';
      headerRight.style.right = 'auto';
      headerRight.style.top = 'auto';
      headerRight.style.paddingRight = '0';
      headerRight.style.justifyContent = 'flex-start';
    }
    if (toggleBtn && toggleBtn.parentElement !== welcomeBanner) {
      welcomeBanner.appendChild(toggleBtn);
      toggleBtn.style.position = 'absolute';
      toggleBtn.style.top = '1.5rem';
      toggleBtn.style.right = '1.5rem';
      toggleBtn.style.display = 'block';
    }
    appHeader.style.display = 'none';
    welcomeBanner.style.paddingTop = '4.5rem';
  } else {
    if (headerRight && headerRight.parentElement !== appHeader) {
      appHeader.appendChild(headerRight);
      headerRight.style.position = 'relative';
      headerRight.style.marginTop = '0';
      headerRight.style.paddingRight = '1rem';
      headerRight.style.justifyContent = 'flex-end';
    }
    if (toggleBtn && appHeader.querySelector('.header-left') && toggleBtn.parentElement !== appHeader.querySelector('.header-left')) {
      appHeader.querySelector('.header-left').appendChild(toggleBtn);
      toggleBtn.style.position = 'absolute';
    }
    appHeader.style.display = 'flex';
    welcomeBanner.style.paddingTop = ''; // Revert to stylesheet
  }
}

window.addEventListener('resize', alignMobileHeader);

function initUtils() {
  initVersionIndicator();
  initSidebar();
  
  // Cerrar popover al hacer click fuera
  document.addEventListener('click', () => {
    const pop = document.getElementById('user-popover');
    if (pop) pop.classList.remove('active');
  });

  // Try to populate header profile
  setTimeout(() => {
    let sb = null;
    if (typeof _supabase !== 'undefined') sb = _supabase;
    else if (typeof window._supabase !== 'undefined') sb = window._supabase;
    
    if (sb) {
      populateHeaderProfile(sb);
      setupAutoLogout();
    }
  }, 500);
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    initUtils();
    alignMobileHeader();
  });
} else {
  initUtils();
  alignMobileHeader();
}

async function populateHeaderProfile(supabaseClient) {
  try {
    const { data: { session } } = await supabaseClient.auth.getSession();
    if (!session) return;
    
    let { data: profileData } = await supabaseClient.from('user_profile').select('first_name, last_name, country').eq('id', session.user.id).limit(1);
    let { data: compData } = await supabaseClient.from('company_profile').select('company_name, industry, country').eq('id', session.user.id).limit(1);
    
    let profile = profileData && profileData.length > 0 ? profileData[0] : null;
    let comp = compData && compData.length > 0 ? compData[0] : null;

    // Check if seller if no client profile found
    if (!profile && !comp) {
      const { data: sProfileData } = await supabaseClient.from('seller_profile').select('first_name, last_name, country').eq('id', session.user.id).limit(1);
      const { data: sCompData } = await supabaseClient.from('seller_company').select('seller_name, location').eq('id', session.user.id).limit(1);
      
      const sProfile = sProfileData && sProfileData.length > 0 ? sProfileData[0] : null;
      const sComp = sCompData && sCompData.length > 0 ? sCompData[0] : null;

      if (sProfile) profile = sProfile;
      if (sComp) comp = { company_name: sComp.seller_name, industry: 'Manufactura', country: sComp.location };
    }

    const userCountry = (comp && comp.country) || (profile && profile.country) || 'MX';
    updateVersionIndicator(userCountry);

    const firstName = profile && profile.first_name ? profile.first_name : (session.user.user_metadata?.first_name || 'Usuario');
    const lastName = profile && profile.last_name ? profile.last_name : (session.user.user_metadata?.last_name || '');

    const companyName = comp && comp.company_name ? comp.company_name : 'Mi Empresa';
    const industry = comp && comp.industry ? comp.industry : 'Sector';

    if (document.getElementById('pop-user-name')) {
      document.getElementById('pop-user-name').textContent = `${firstName} ${lastName}`.trim();
    }
    if (document.getElementById('pop-user-email')) {
      document.getElementById('pop-user-email').textContent = session.user.email;
    }
    if (document.getElementById('company-name-display')) {
      document.getElementById('company-name-display').textContent = companyName;
    }
    if (document.getElementById('dash-industry-val')) {
      document.getElementById('dash-industry-val').textContent = industry;
    }

    // Cambiar icono de industria
    const iconDisplay = document.getElementById('badge-industry-icon');
    if (iconDisplay) {
      const industryLower = industry.toLowerCase();
      let iconSvg = '<svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 21h18M3 7v1a3 3 0 0 0 6 0V7m0 1a3 3 0 0 0 6 0V7m0 1a3 3 0 0 0 6 0V7M4 7l1-4h14l1 4"/></svg>';
      if (industryLower === 'restaurantes') iconSvg = '<svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2M7 2v4M21 15V2v0a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7M12 15v7M15 15v7"/></svg>';
      else if (industryLower === 'hospitalidad') iconSvg = '<svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M2 22V4a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v18M10 18h4M12 18v4M7 6h.01M7 10h.01M7 14h.01M17 6h.01M17 10h.01M17 14h.01"/></svg>';
      else if (industryLower === 'industrial') iconSvg = '<svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M2 20V10l10-4 10 4v10H2Z"/><path d="M17 11v9M7 11v9M12 6v14"/></svg>';
      else if (industryLower === 'salud') iconSvg = '<svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>';
      else if (industryLower === 'educacion') iconSvg = '<svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="m22 10-10-5L2 10l10 5 10-5Z"/><path d="M6 12v5c0 2 2 3 6 3s6-1 6-3v-5"/></svg>';
      else if (industryLower === 'servicios') iconSvg = '<svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a2 2 0 0 1-2.83-2.83l-3.94 3.6ZM9.14 14.86l2.83 2.83M5 19l2.83-2.83m1.41-5.66 2.12 2.12a2 2 0 0 0 2.83 0l3.54-3.54M3.5 13.5l3.54-3.54a2 2 0 0 1 2.83 0l2.12 2.12"/></svg>';
      
      iconDisplay.innerHTML = iconSvg;
      iconDisplay.style.color = "var(--color-cyan)";
    }

    window.dispatchEvent(new CustomEvent('userProfileLoaded', { detail: { industry, companyName, userCountry } }));
  } catch (err) {
    console.error('Error populating header profile', err);
  }
}

function toggleUserPopover(e) {
  if (e) e.stopPropagation();
  const pop = document.getElementById('user-popover');
  if (pop) pop.classList.toggle('active');
}

function getCurrencyConfig(country) {
  const isColombia = country === 'CO' || country === 'Colombia';
  return {
    code: isColombia ? 'COP' : 'MXN',
    locale: isColombia ? 'es-CO' : 'es-MX',
    symbol: '$'
  };
}

function formatCurrency(val, country = 'MX') {
  const config = getCurrencyConfig(country);
  return new Intl.NumberFormat(config.locale, {
    style: 'currency',
    currency: config.code,
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  }).format(val);
}

// Auto-logout after inactivity
const WARNING_TIME = 4 * 60 * 1000; // 4 minutos
const LOGOUT_TIME = 5 * 60 * 1000;  // 5 minutos
let inactivityTimer;
let logoutTimer;
let isWarningActive = false;

function resetInactivityTimer() {
  if (isWarningActive) return; // Do not reset if warning is shown
  
  clearTimeout(inactivityTimer);
  clearTimeout(logoutTimer);
  
  inactivityTimer = setTimeout(showInactivityWarning, WARNING_TIME);
}

function showInactivityWarning() {
  isWarningActive = true;
  
  let modal = document.getElementById('inactivity-modal');
  if (!modal) {
    modal = document.createElement('div');
    modal.id = 'inactivity-modal';
    modal.className = 'modal-overlay active';
    modal.style.zIndex = '9999';
    modal.innerHTML = `
      <div class="modal-content" style="background: white; border-radius: 1.5rem; max-width: 400px; width: 90%; text-align: center; padding: 2.5rem 2rem; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); border: 1px solid #E2E8F0;">
        <div style="width: 56px; height: 56px; background: #FFFBEB; color: #D97706; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1.5rem;">
          <svg width="28" height="28" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
        </div>
        <h2 style="font-family: var(--font-family-heading, 'Outfit'); color: var(--color-navy, #0f172a); font-size: 1.5rem; margin-bottom: 0.5rem; font-weight: 700;">Tu sesión está por expirar</h2>
        <p style="color: var(--color-text-secondary, #64748b); font-size: 0.875rem; margin-bottom: 2rem; line-height: 1.5;">Llevas un tiempo inactivo. Por tu seguridad, cerraremos tu sesión automáticamente en 1 minuto.</p>
        <button onclick="keepSessionActive()" class="btn btn-primary" style="width: 100%; padding: 0.875rem; font-size: 0.95rem; background: var(--color-cyan, #06b6d4); color: var(--color-navy, #0f172a); border: none; border-radius: 12px; font-weight: 700; cursor: pointer; transition: all 0.2s; box-shadow: 0 4px 6px -1px rgba(6, 182, 212, 0.2);">Mantener Sesión Activa</button>
      </div>
    `;
    document.body.appendChild(modal);
  } else {
    modal.classList.add('active');
  }

  logoutTimer = setTimeout(logoutUser, LOGOUT_TIME - WARNING_TIME);
}

window.keepSessionActive = function() {
  isWarningActive = false;
  clearTimeout(logoutTimer);
  const modal = document.getElementById('inactivity-modal');
  if (modal) modal.classList.remove('active');
  resetInactivityTimer();
};

async function logoutUser() {
  if (typeof _supabase !== 'undefined') {
    await _supabase.auth.signOut();
    const path = window.location.pathname;
    let target = 'login.html';
    if (path.includes('seller')) target = 'login.seller.html';
    else if (path.includes('mi_') || path.includes('mi-')) target = 'mi-login.html';
    else if (path.includes('admin')) target = 'login.admin.html';
    
    window.location.href = target + '?reason=timeout';
  }
}

function setupAutoLogout() {
  const path = window.location.pathname;
  if (path.includes('login') || path.endsWith('index.html') || path === '/' || path.endsWith('dotacian/')) {
    return;
  }
  
  const events = ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart'];
  events.forEach(event => {
    document.addEventListener(event, resetInactivityTimer, { passive: true });
  });
  
  resetInactivityTimer();
}

// Admin Leads Badge
document.addEventListener('DOMContentLoaded', () => {
  if (window.location.pathname.includes('admin') && !window.location.pathname.includes('login')) {
    setTimeout(async () => {
      const navLeads = document.getElementById('nav-leads');
      if (navLeads && typeof supabase !== 'undefined') {
        try {
          let localSupa = window._supabase;
          if (!localSupa) {
            localSupa = supabase.createClient('https://awuhvewotmwelurmjvmu.supabase.co', 'sb_publishable_4WG86Fal8RQ3tV0sNXZIow_hikHt0Aq', { auth: { storageKey: 'dotacian-client-token', multiTab: false } });
          }
          
          const { count, error } = await localSupa
            .from('leads_dotacian')
            .select('*', { count: 'exact', head: true })
            .eq('status', 'nuevo');
          
          if (!error && count > 0) {
            navLeads.style.display = 'flex';
            navLeads.style.justifyContent = 'space-between';
            navLeads.style.alignItems = 'center';
            
            const badge = document.createElement('span');
            badge.style.background = '#EF4444';
            badge.style.color = 'white';
            badge.style.borderRadius = '50%';
            badge.style.width = '20px';
            badge.style.height = '20px';
            badge.style.display = 'flex';
            badge.style.alignItems = 'center';
            badge.style.justifyContent = 'center';
            badge.style.fontSize = '0.7rem';
            badge.style.fontWeight = '700';
            badge.style.boxShadow = '0 0 0 2px #0F172A';
            badge.textContent = count > 9 ? '+9' : count;
            
            navLeads.appendChild(badge);
          }
        } catch(err) {
          console.error('Error fetching leads count for badge:', err);
        }
      }
    }, 1200); // Give Supabase time to initialize
  }
});
