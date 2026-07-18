(function () {
  const isClosed = localStorage.getItem('dotacian_widget_closed') === 'true';

  // 1. Inyectar HTML del widget
  const widgetHTML = `
    <div id="dotWidgetContainer" class="dot-widget-container">
      <div id="dotWidgetPanel" class="dot-widget-panel ${isClosed ? '' : 'active'}">
        <div class="dot-widget-header" style="background: white; border: none; padding: 1.5rem 1.5rem 0.5rem; display: flex; justify-content: space-between; align-items: center;">
           <div style="display:flex; align-items:center; gap:10px;">
             <div style="width:36px;height:36px;background:var(--color-cyan);border-radius:50%;display:flex;align-items:center;justify-content:center;color:white;font-weight:bold;font-size:1.2rem;">d</div>
           </div>
           <button class="dot-widget-close" id="dotWidgetClose" style="background: rgba(0,0,0,0.05); border: none; width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; color: #64748B; cursor: pointer; transition: background 0.2s;">&times;</button>
        </div>
        
        <div class="dot-widget-body" id="dotChatHistory" style="padding: 1rem 1.5rem 0; flex: 1; overflow-y: auto; display: flex; flex-direction: column; gap: 1rem;">
           <div id="dotWelcomeState" style="display: flex; flex-direction: column; align-items: center; justify-content: center; flex: 1; text-align: center; margin-bottom: 2rem;">
              <h2 style="font-size: 2rem; color: #64748B; font-weight: 700; line-height: 1.2; margin-bottom: 2rem; font-family: var(--font-family-heading);">¿Cómo te puedo<br>ayudar hoy?</h2>
              <div id="dotQuickPrompts" style="display: flex; gap: 0.5rem; justify-content: center; flex-wrap: wrap;"></div>
           </div>
        </div>
        
        <div class="dot-widget-footer" style="background: white; border: none; padding: 1rem 1.5rem 1.5rem;">
          <input type="file" id="dotFileInput" accept="application/pdf" style="display: none;">
          <div style="display: flex; align-items: center; border: 1px solid #E2E8F0; border-radius: 9999px; padding: 0.5rem 1rem; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); background: #F8FAFC; width: 100%;">
            <button class="dot-btn-icon" id="btn-attach-widget" title="Adjuntar archivo" style="background: transparent; color: #64748B; border: none; cursor: pointer; padding: 0.25rem;">
              <svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                <polyline points="17 8 12 3 7 8" />
                <line x1="12" y1="3" x2="12" y2="15" />
              </svg>
            </button>
            <span id="file-name-display" style="display:none; font-size: 0.75rem; color: #10B981; max-width: 60px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; margin-left: 0.5rem;"></span>
            <input type="text" id="dotChatInput" placeholder="Pregunta a dot..." style="flex:1; border:none; outline:none; background:transparent; padding:0 15px; font-family:inherit; font-size:1rem; color: var(--color-navy); min-width:0;">
            <button class="dot-btn-icon" id="btn-send-widget" title="Enviar" style="background: transparent; color: #64748B; border: none; cursor: pointer; padding: 0.25rem; transition: color 0.2s;" onmouseover="this.style.color='var(--color-cyan)';" onmouseout="this.style.color='#64748B';">
              <svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path d="M22 2L11 13" />
                <polygon points="22 2 15 22 11 13 2 9 22 2" />
              </svg>
            </button>
          </div>
        </div>
      </div>
      <button id="dotWidgetFab" class="dot-widget-fab" style="transform: scale(${isClosed ? '1' : '0'});">
         <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path>
         </svg>
      </button>
    </div>
    <style>
      .dot-widget-panel { position: fixed !important; width: 420px; box-shadow: -4px 0 30px rgba(0,0,0,0.06); z-index: 1000; }
      body.dot-widget-open .main-content { margin-right: 420px; }
      body.dot-widget-open .app-header { right: 420px; }
      .main-content, .app-header { transition: margin-right 0.4s cubic-bezier(0.165, 0.84, 0.44, 1), right 0.4s cubic-bezier(0.165, 0.84, 0.44, 1); }
      .dot-quick-prompt {
        border: 1px solid #E2E8F0; border-radius: 9999px; background: white; padding: 0.6rem 1rem; font-size: 0.85rem; color: #475569; cursor: pointer; transition: all 0.2s; box-shadow: 0 1px 2px rgba(0,0,0,0.02);
      }
      .dot-quick-prompt:hover {
        background: #F8FAFC; border-color: #CBD5E1; color: var(--color-navy); transform: translateY(-1px); box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
      }
      .dot-bubble { max-width: 90%; padding: 1rem 1.2rem; border-radius: 1rem; font-size: 0.95rem; line-height: 1.5; }
      .dot-bubble.assistant { background: #F1F5F9; color: var(--color-navy); border-top-left-radius: 0.25rem; }
      .dot-bubble.user { background: var(--color-cyan); color: white; border-top-right-radius: 0.25rem; align-self: flex-end; }
    </style>
  `;
  document.body.insertAdjacentHTML('beforeend', widgetHTML);

  // Inicializar clase en el body si está abierto
  if (!isClosed) {
    document.body.classList.add('dot-widget-open');
  }

  // 2. Elementos DOM
  const fab = document.getElementById('dotWidgetFab');
  const panel = document.getElementById('dotWidgetPanel');
  const closeBtn = document.getElementById('dotWidgetClose');
  const history = document.getElementById('dotChatHistory');
  const input = document.getElementById('dotChatInput');
  const btnSend = document.getElementById('btn-send-widget');
  const btnAttach = document.getElementById('btn-attach-widget');
  const fileInput = document.getElementById('dotFileInput');
  const fileNameDisplay = document.getElementById('file-name-display');
  const welcomeState = document.getElementById('dotWelcomeState');

  // 3. Estado
  let dotSessionId = localStorage.getItem('dotacian_chat_session');
  if (!dotSessionId) {
    dotSessionId = crypto.randomUUID ? crypto.randomUUID() : Math.random().toString(36).substring(2, 15);
    localStorage.setItem('dotacian_chat_session', dotSessionId);
  }
  let currentFileBase64 = null;
  let currentFileName = null;
  
  // State machine for special flows
  window.dotConversationState = 'default';
  window.dotConversationContext = null;

  // Supabase (usa la instancia _supabase de utils.js o app.html)
  // Nota: asegúrate de que app.html tenga window._supabase
  const SUPABASE_URL = 'https://awuhvewotmwelurmjvmu.supabase.co';
  const SUPABASE_ANON_KEY = 'sb_publishable_4WG86Fal8RQ3tV0sNXZIow_hikHt0Aq';
  const supabaseClient = window._supabase || (window.supabase ? window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, { auth: { storageKey: 'dotacian-client-token', multiTab: false } }) : null);

  // 4. Lógica de UI
  fab.addEventListener('click', () => {
    panel.classList.add('active');
    document.body.classList.add('dot-widget-open');
    fab.style.transform = 'scale(0)';
    localStorage.setItem('dotacian_widget_closed', 'false');
    input.focus();
    updateDotPrompts();
  });

  closeBtn.addEventListener('click', () => {
    panel.classList.remove('active');
    document.body.classList.remove('dot-widget-open');
    fab.style.transform = 'scale(1)';
    localStorage.setItem('dotacian_widget_closed', 'true');
  });

  btnAttach.addEventListener('click', () => fileInput.click());

  fileInput.addEventListener('change', (event) => {
    const file = event.target.files[0];
    if (!file) return;
    if (file.type !== 'application/pdf') {
      alert("Por favor, sube solo archivos PDF.");
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      alert("El archivo es muy grande. Máximo 5MB.");
      return;
    }

    const reader = new FileReader();
    reader.onload = function (e) {
      const base64String = e.target.result.split(',')[1];
      currentFileBase64 = base64String;
      currentFileName = file.name;
      fileNameDisplay.textContent = file.name;
      fileNameDisplay.style.display = 'inline-block';
    };
    reader.readAsDataURL(file);
  });

  input.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') handleDotSubmit();
  });

  btnSend.addEventListener('click', handleDotSubmit);

  function handleDotSubmit() {
    const text = input.value;
    sendDotMessage(text);
  }

  async function sendDotMessage(text) {
    if ((!text || text.trim() === '') && !currentFileBase64) return;

    // Ocultar mensaje de bienvenida grande si existe
    const welcomeState = document.getElementById('dotWelcomeState');
    if (welcomeState && welcomeState.style.display !== 'none') {
      welcomeState.style.display = 'none';
    }

    // Limpiar input
    input.value = '';
    const sentText = text || "Revisa este documento por favor.";

    // Agregar mensaje del usuario
    const userBubble = document.createElement('div');
    userBubble.className = 'dot-bubble user';
    userBubble.innerHTML = sentText + (currentFileName ? `<br><small style="color: #A7F3D0;">📄 ${currentFileName}</small>` : '');
    history.appendChild(userBubble);

    const fileToSend = currentFileBase64;
    currentFileBase64 = null;
    currentFileName = null;
    fileNameDisplay.style.display = 'none';
    fileInput.value = '';
    history.scrollTop = history.scrollHeight;

    // Intercept special flows
    if (window.dotConversationState === 'garment_config_ask_provider') {
      const lowerText = sentText.toLowerCase();
      
      // Check negative/proposals first to avoid false positives like "no tengo proveedor"
      if (lowerText.includes('no ') || lowerText.includes('no,') || lowerText.includes('nuevo') || lowerText.includes('propuesta') || lowerText.includes('studio') || lowerText.includes('diseñar')) {
        // Wants proposals -> open Dotacian Studio
        window.dotConversationState = 'default';
        const assistantBubble = document.createElement('div');
        assistantBubble.className = 'dot-bubble assistant';
        assistantBubble.innerHTML = "¡Entendido! Vamos a diseñar desde cero. Abriendo Dotacian Studio... 🚀";
        history.appendChild(assistantBubble);
        history.scrollTop = history.scrollHeight;
        
        setTimeout(() => {
          window.location.href = 'studio.html';
        }, 1500);
        return;
      } else if (lowerText.includes('si ') || lowerText.includes('sí ') || lowerText.includes('tengo') || lowerText.includes('ya') || lowerText.includes('proveedor')) {
        // Wants to use own provider
        window.dotConversationState = 'garment_config_ask_url';
        const assistantBubble = document.createElement('div');
        assistantBubble.className = 'dot-bubble assistant';
        assistantBubble.innerHTML = "¡Perfecto! Por favor compárteme la URL de la página web de tu proveedor para poder extraer la información de su catálogo virtual.";
        history.appendChild(assistantBubble);
        history.scrollTop = history.scrollHeight;
        return;
      } else {
        // Unclear response
        const assistantBubble = document.createElement('div');
        assistantBubble.className = 'dot-bubble assistant';
        assistantBubble.innerHTML = "¿Me podrías aclarar? ¿Ya tienes un proveedor o prefieres que te pase propuestas?";
        history.appendChild(assistantBubble);
        history.scrollTop = history.scrollHeight;
        return;
      }
    }
    
    if (window.dotConversationState === 'garment_config_ask_url') {
      if (sentText.includes('http') || sentText.includes('www') || sentText.includes('.com')) {
        window.dotConversationState = 'default';
        const assistantBubble = document.createElement('div');
        assistantBubble.className = 'dot-bubble assistant';
        assistantBubble.innerHTML = "¡Excelente! Estoy analizando el catálogo virtual... 🤖🔍<br><br><i>(Simulación de proceso RAG: extrayendo prendas y características de la web proporcionada...)</i><br><br>He procesado la información. ¿Qué prendas quieres agregar al rol?";
        history.appendChild(assistantBubble);
        history.scrollTop = history.scrollHeight;
        return;
      }
    }

    // Duplicate block removed

    // Indicador escribiendo
    const typingBubble = document.createElement('div');
    typingBubble.className = 'dot-bubble assistant';
    typingBubble.id = 'dotTyping';
    typingBubble.innerHTML = '<span style="font-size: 0.8rem; color: #94A3B8;">dot está analizando...</span>';
    history.appendChild(typingBubble);
    history.scrollTop = history.scrollHeight;

    try {
      let aiMessage = "¡Claro! Encontré esto que podría interesarte:";
      let companyId = null;

      if (supabaseClient) {
        const { data: { session } } = await supabaseClient.auth.getSession();
        companyId = session?.user?.id || null;
      }

      const { data, error: functionError } = await supabaseClient.functions.invoke('dot-chat', {
        body: {
          text: sentText,
          session_id: dotSessionId,
          company_id: companyId,
          file_base64: fileToSend
        }
      });

      if (functionError) {
        throw new Error("Error interno del servidor");
      } else if (data && data.error) {
        throw new Error("Error de Gemini: " + data.error);
      } else if (data) {
        aiMessage = data.message || aiMessage;
      }

      const tBubble = document.getElementById('dotTyping');
      if (tBubble) tBubble.remove();

      const assistantBubble = document.createElement('div');
      assistantBubble.className = 'dot-bubble assistant';
      const parsedMessage = typeof marked !== 'undefined' && typeof DOMPurify !== 'undefined' 
        ? DOMPurify.sanitize(marked.parse(aiMessage)) 
        : aiMessage;
      assistantBubble.innerHTML = parsedMessage;

      history.appendChild(assistantBubble);
      history.scrollTop = history.scrollHeight;

    } catch (err) {
      console.error(err);
      const tBubble = document.getElementById('dotTyping');
      if (tBubble) tBubble.remove();
      const errBubble = document.createElement('div');
      errBubble.className = 'dot-bubble assistant';
      errBubble.style.color = '#991B1B';
      errBubble.style.background = '#FEF2F2';
      errBubble.textContent = "Ups, hubo un problema: " + err.message;
      history.appendChild(errBubble);
      history.scrollTop = history.scrollHeight;
    }
  }

  function updateDotPrompts() {
    const container = document.getElementById('dotQuickPrompts');
    if (!container || container.children.length > 0) return;

    const prompts = [
      { text: 'Activar un nuevo rol', url: '/app/roles' },
      { text: 'Crear un nuevo empleado', url: '/app/empleados' },
      { text: 'Realizar pedido (Cotizar)', url: '/cotizaciones.html' }
    ];

    prompts.forEach(p => {
      const btn = document.createElement('button');
      btn.className = 'dot-quick-prompt';
      btn.textContent = p.text;
      btn.onclick = () => {
        if (p.url) {
          window.location.href = p.url;
        } else {
          sendDotMessage(p.query);
        }
      };
      btn.style.fontFamily = "'Inter', sans-serif";
      btn.style.background = 'white';
      btn.style.border = '1px solid #E2E8F0';
      btn.style.borderRadius = '20px';
      btn.style.padding = '0.5rem 1rem';
      btn.style.fontSize = '0.8rem';
      btn.style.color = 'var(--color-navy)';
      btn.style.cursor = 'pointer';
      btn.style.whiteSpace = 'nowrap';
      btn.style.boxShadow = '0 1px 2px rgba(0,0,0,0.05)';
      btn.style.margin = '2px';
      btn.onmouseover = () => { btn.style.background = '#F8FAFC'; btn.style.borderColor = '#CBD5E1'; };
      btn.onmouseout = () => { btn.style.background = 'white'; btn.style.borderColor = '#E2E8F0'; };
      container.appendChild(btn);
    });
  }

  // Global functions
  window.openDotWithContext = function(contextType, data = {}) {
    panel.classList.add('active');
    fab.style.transform = 'scale(0)';
    input.focus();
    
    window.dotConversationContext = data;
    
    if (contextType === 'garment_config') {
      window.dotConversationState = 'garment_config_ask_provider';
      const roleName = data.role || 'este rol';
      
      const assistantBubble = document.createElement('div');
      assistantBubble.className = 'dot-bubble assistant';
      assistantBubble.innerHTML = `Veo que quieres agregar prendas para <strong>${roleName}</strong>. ¿Tienes ya un proveedor seleccionado y te gustaría trabajar con él, o quieres que yo te pase propuestas de nuevos proveedores?`;
      history.appendChild(assistantBubble);
      history.scrollTop = history.scrollHeight;
      
      // Hide quick prompts if they exist
      const qp = document.getElementById('dotQuickPrompts');
      if (qp) qp.style.display = 'none';
    }
  };

})();
