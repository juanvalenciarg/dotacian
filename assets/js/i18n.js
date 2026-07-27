// Diccionario de traducciones del portal (app/*). Un solo archivo HTML por
// página; el texto se intercambia en tiempo de ejecución según el idioma
// activo, en vez de mantener una copia .html duplicada por idioma (como en
// el sitio público). El idioma se persiste en localStorage y en
// company_profile.language en Supabase.
const I18N = {
  es: {
    // Sidebar
    'nav.dashboard': 'Dashboard',
    'nav.roles': 'Roles',
    'nav.empleados': 'Empleados',
    'nav.uniformes': 'Uniformes',
    'nav.bodega': 'Bodega',

    // User popover
    'popover.user': 'Usuario',
    'popover.email': 'Correo Electrónico',
    'popover.country': 'País',
    'popover.language': 'Idioma',
    'popover.alerts': 'Alertas',
    'popover.settings': 'Configuración',
    'popover.logout': 'Cerrar Sesión',

    // Page header
    'page.rolesTitle': 'Configuración de Roles',
    'page.rolesSubtitle': 'Crea y administra los roles de tu empresa.',
    'page.rolesHeading': 'Roles de tu empresa',
    'loading.roles': 'Cargando roles...',

    // Create-role card
    'card.createNew': 'Crear Nuevo Rol',
    'card.createNewDesc': 'Personaliza la estructura de tu equipo',
    'card.assetsAssigned': 'Activos asignados',
    'card.area': 'Área',
    'card.unassigned': 'Sin asignar',
    'card.enabled': 'Habilitado',
    'card.disabled': 'Inhabilitado',
    'card.configureAssets': 'Configurar Activos',
    'card.asset': 'Activo',
    'card.assets': 'Activos',
    'card.deleteRole': 'Eliminar rol',

    // Confirm modal
    'confirm.defaultTitle': 'Confirmar acción',
    'confirm.deleteRoleTitle': 'Eliminar rol',
    'confirm.deleteRoleMsg': '¿Eliminar el rol "{name}"? Esta acción no se puede deshacer.',
    'confirm.cancel': 'Cancelar',
    'confirm.accept': 'Aceptar',
    'confirm.delete': 'Eliminar',

    // Role Config modal
    'roleConfig.titleDefault': 'Configurar Activos',
    'roleConfig.titleWithName': 'Configurar: {name}',
    'roleConfig.desc': 'Define los activos físicos y digitales que componen la plantilla base de este rol.',
    'roleConfig.area': 'Área',
    'roleConfig.selectArea': 'Selecciona un área...',
    'roleConfig.areaCustomPlaceholder': 'Escribe el área...',
    'roleConfig.subarea': 'Subárea (opcional)',
    'roleConfig.subareaPlaceholder': 'Ej. Cocina',
    'roleConfig.addAsset': '+ Agregar Activo',
    'roleConfig.assetName': 'Nombre del Activo',
    'roleConfig.assetNamePlaceholder': 'Ej. Impresora, Silla ergonómica...',
    'roleConfig.category': 'Categoría',
    'roleConfig.type': 'Tipo',
    'roleConfig.qty': 'Cant.',
    'roleConfig.cancel': 'Cancelar',
    'roleConfig.add': 'Agregar',
    'roleConfig.saveChanges': 'Guardar Cambios',
    'roleConfig.loadingConfig': 'Cargando configuración...',
    'roleConfig.emptyState': 'Este rol todavía no tiene activos asignados. Usa "+ Agregar Activo" para empezar.',

    'reposicion.question': '¿Requiere reposición?',
    'reposicion.every': 'cada',
    'reposicion.months': 'meses',

    // Area options (shared)
    'area.direccion': 'Dirección / Gerencia',
    'area.administracion': 'Administración',
    'area.operaciones': 'Operaciones',
    'area.ventas': 'Ventas',
    'area.produccion': 'Producción / Cocina',
    'area.logistica': 'Logística',
    'area.seguridad': 'Seguridad',
    'area.limpieza': 'Limpieza',
    'area.atencion': 'Atención al Cliente',
    'area.ti': 'TI',
    'area.rrhh': 'RRHH',
    'area.otra': 'Otra (especificar)',

    // Asset categories / types
    'category.fisico': 'Físico',
    'category.digital': 'Digital',
    'type.uniforme': 'Uniforme',
    'type.computo': 'Cómputo',
    'type.equipo': 'Herramientas/EPP',
    'type.acceso': 'Acceso',
    'type.vehiculo': 'Vehículo',
    'type.licencia': 'Licencia',
    'type.acceso_digital': 'Acceso Digital',

    // Asset catalog tree — subcategory labels
    'catalog.computo.label': 'Cómputo',
    'catalog.uniforme.label': 'Uniformes',
    'catalog.acceso.label': 'Acceso',
    'catalog.vehiculo.label': 'Vehículos',
    'catalog.equipo.label': 'Herramientas / EPP',
    'catalog.licencia.label': 'Licencias / Software',
    'catalog.acceso_digital.label': 'Accesos digitales',

    // Asset catalog tree — items
    'item.laptop': 'Laptop',
    'item.monitor': 'Monitor',
    'item.cargadorLaptop': 'Cargador de laptop',
    'item.mouse': 'Mouse',
    'item.teclado': 'Teclado',
    'item.audifonos': 'Audífonos',
    'item.camiseta': 'Camiseta/Camisa',
    'item.pantalon': 'Pantalón',
    'item.casco': 'Casco',
    'item.zapatos': 'Zapatos/Calzado',
    'item.chaqueta': 'Chaqueta',
    'item.delantal': 'Delantal',
    'item.tarjetaAcceso': 'Tarjeta de acceso',
    'item.llaveOficina': 'Llave de oficina',
    'item.gafete': 'Gafete/Credencial',
    'item.auto': 'Auto',
    'item.moto': 'Moto',
    'item.bicicleta': 'Bicicleta',
    'item.kitHerramientas': 'Kit de herramientas',
    'item.radio': 'Radio de comunicación',
    'item.epp': 'Equipo de protección personal',
    'item.googleWorkspace': 'Google Workspace',
    'item.microsoft365': 'Microsoft 365',
    'item.crm': 'CRM',
    'item.erp': 'ERP',
    'item.vpn': 'VPN',
    'item.usuarioSistema': 'Usuario de sistema interno',
    'item.correoCorp': 'Correo corporativo',
    'item.otro': 'Otro (opcional)',
    'item.cantidad': 'Cantidad',

    // New Role modal
    'newRole.title': 'Crear Nuevo Rol',
    'newRole.desc': 'Define un nuevo perfil operativo para tu empresa.',
    'newRole.roleName': 'Nombre del Rol',
    'newRole.roleNamePlaceholder': 'Ej. Supervisor de Piso',
    'newRole.description': 'Descripción',
    'newRole.descriptionPlaceholder': 'Describe brevemente las funciones de este rol...',
    'newRole.assetTypesLabel': 'Tipo de activos a entregar',
    'newRole.fisico': 'Físico',
    'newRole.digital': 'Digital',
    'newRole.cancel': 'Cancelar',
    'newRole.createBtn': 'Crear Rol',

    // Toasts / alerts
    'toast.roleDeletedTitle': 'Rol Eliminado',
    'toast.roleDeletedMsg': 'El rol "{name}" fue eliminado.',
    'toast.errorTitle': 'Error',
    'toast.errorDeletingRole': 'Hubo un problema eliminando el rol.',
    'toast.errorUpdatingRole': 'Hubo un problema actualizando el rol.',
    'toast.configSavedTitle': 'Configuración Guardada',
    'toast.configSavedMsg': 'La plantilla de activos para este rol ha sido actualizada.',
    'toast.errorSavingConfig': 'Hubo un problema guardando la configuración.',
    'toast.roleCreatedTitle': 'Rol Creado',
    'toast.roleCreatedMsg': 'El rol "{name}" fue creado exitosamente.',
    'toast.errorCreatingRole': 'Hubo un problema creando el rol.',
    'alert.enterRoleName': 'Por favor ingresa el nombre del rol',
    'alert.enterAssetName': 'Por favor ingresa el nombre del activo'
  },

  en: {
    'nav.dashboard': 'Dashboard',
    'nav.roles': 'Roles',
    'nav.empleados': 'Employees',
    'nav.uniformes': 'Uniforms',
    'nav.bodega': 'Warehouse',

    'popover.user': 'User',
    'popover.email': 'Email',
    'popover.country': 'Country',
    'popover.language': 'Language',
    'popover.alerts': 'Alerts',
    'popover.settings': 'Settings',
    'popover.logout': 'Log Out',

    'page.rolesTitle': 'Role Configuration',
    'page.rolesSubtitle': "Create and manage your company's roles.",
    'page.rolesHeading': "Your company's roles",
    'loading.roles': 'Loading roles...',

    'card.createNew': 'Create New Role',
    'card.createNewDesc': "Customize your team's structure",
    'card.assetsAssigned': 'Assets assigned',
    'card.area': 'Area',
    'card.unassigned': 'Unassigned',
    'card.enabled': 'Enabled',
    'card.disabled': 'Disabled',
    'card.configureAssets': 'Configure Assets',
    'card.asset': 'Asset',
    'card.assets': 'Assets',
    'card.deleteRole': 'Delete role',

    'confirm.defaultTitle': 'Confirm action',
    'confirm.deleteRoleTitle': 'Delete role',
    'confirm.deleteRoleMsg': 'Delete the role "{name}"? This action cannot be undone.',
    'confirm.cancel': 'Cancel',
    'confirm.accept': 'Accept',
    'confirm.delete': 'Delete',

    'roleConfig.titleDefault': 'Configure Assets',
    'roleConfig.titleWithName': 'Configure: {name}',
    'roleConfig.desc': "Define the physical and digital assets that make up this role's base template.",
    'roleConfig.area': 'Area',
    'roleConfig.selectArea': 'Select an area...',
    'roleConfig.areaCustomPlaceholder': 'Type the area...',
    'roleConfig.subarea': 'Subarea (optional)',
    'roleConfig.subareaPlaceholder': 'E.g. Kitchen',
    'roleConfig.addAsset': '+ Add Asset',
    'roleConfig.assetName': 'Asset Name',
    'roleConfig.assetNamePlaceholder': 'E.g. Printer, Ergonomic chair...',
    'roleConfig.category': 'Category',
    'roleConfig.type': 'Type',
    'roleConfig.qty': 'Qty.',
    'roleConfig.cancel': 'Cancel',
    'roleConfig.add': 'Add',
    'roleConfig.saveChanges': 'Save Changes',
    'roleConfig.loadingConfig': 'Loading configuration...',
    'roleConfig.emptyState': 'This role doesn\'t have any assets assigned yet. Use "+ Add Asset" to get started.',

    'reposicion.question': 'Needs replenishment?',
    'reposicion.every': 'every',
    'reposicion.months': 'months',

    'area.direccion': 'Management / Executive',
    'area.administracion': 'Administration',
    'area.operaciones': 'Operations',
    'area.ventas': 'Sales',
    'area.produccion': 'Production / Kitchen',
    'area.logistica': 'Logistics',
    'area.seguridad': 'Security',
    'area.limpieza': 'Cleaning',
    'area.atencion': 'Customer Service',
    'area.ti': 'IT',
    'area.rrhh': 'HR',
    'area.otra': 'Other (specify)',

    'category.fisico': 'Physical',
    'category.digital': 'Digital',
    'type.uniforme': 'Uniform',
    'type.computo': 'Computing',
    'type.equipo': 'Tools/PPE',
    'type.acceso': 'Access',
    'type.vehiculo': 'Vehicle',
    'type.licencia': 'License',
    'type.acceso_digital': 'Digital Access',

    'catalog.computo.label': 'Computing',
    'catalog.uniforme.label': 'Uniforms',
    'catalog.acceso.label': 'Access',
    'catalog.vehiculo.label': 'Vehicles',
    'catalog.equipo.label': 'Tools / PPE',
    'catalog.licencia.label': 'Licenses / Software',
    'catalog.acceso_digital.label': 'Digital access',

    'item.laptop': 'Laptop',
    'item.monitor': 'Monitor',
    'item.cargadorLaptop': 'Laptop charger',
    'item.mouse': 'Mouse',
    'item.teclado': 'Keyboard',
    'item.audifonos': 'Headphones',
    'item.camiseta': 'T-shirt/Shirt',
    'item.pantalon': 'Pants',
    'item.casco': 'Helmet',
    'item.zapatos': 'Shoes/Footwear',
    'item.chaqueta': 'Jacket',
    'item.delantal': 'Apron',
    'item.tarjetaAcceso': 'Access card',
    'item.llaveOficina': 'Office key',
    'item.gafete': 'Badge/ID',
    'item.auto': 'Car',
    'item.moto': 'Motorcycle',
    'item.bicicleta': 'Bicycle',
    'item.kitHerramientas': 'Tool kit',
    'item.radio': 'Two-way radio',
    'item.epp': 'Personal protective equipment',
    'item.googleWorkspace': 'Google Workspace',
    'item.microsoft365': 'Microsoft 365',
    'item.crm': 'CRM',
    'item.erp': 'ERP',
    'item.vpn': 'VPN',
    'item.usuarioSistema': 'Internal system account',
    'item.correoCorp': 'Corporate email',
    'item.otro': 'Other (optional)',
    'item.cantidad': 'Quantity',

    'newRole.title': 'Create New Role',
    'newRole.desc': 'Define a new operational profile for your company.',
    'newRole.roleName': 'Role Name',
    'newRole.roleNamePlaceholder': 'E.g. Floor Supervisor',
    'newRole.description': 'Description',
    'newRole.descriptionPlaceholder': "Briefly describe this role's responsibilities...",
    'newRole.assetTypesLabel': 'Types of assets to provide',
    'newRole.fisico': 'Physical',
    'newRole.digital': 'Digital',
    'newRole.cancel': 'Cancel',
    'newRole.createBtn': 'Create Role',

    'toast.roleDeletedTitle': 'Role Deleted',
    'toast.roleDeletedMsg': 'The role "{name}" was deleted.',
    'toast.errorTitle': 'Error',
    'toast.errorDeletingRole': 'There was a problem deleting the role.',
    'toast.errorUpdatingRole': 'There was a problem updating the role.',
    'toast.configSavedTitle': 'Configuration Saved',
    'toast.configSavedMsg': "This role's asset template has been updated.",
    'toast.errorSavingConfig': 'There was a problem saving the configuration.',
    'toast.roleCreatedTitle': 'Role Created',
    'toast.roleCreatedMsg': 'The role "{name}" was created successfully.',
    'toast.errorCreatingRole': 'There was a problem creating the role.',
    'alert.enterRoleName': 'Please enter the role name',
    'alert.enterAssetName': 'Please enter the asset name'
  }
};

(function () {
  window.currentLang = localStorage.getItem('dotacian_lang') || 'es';

  window.t = function (key, vars) {
    const dict = I18N[window.currentLang] || I18N.es;
    let str = dict[key] || I18N.es[key] || key;
    if (vars) {
      Object.keys(vars).forEach(k => {
        str = str.replace('{' + k + '}', vars[k]);
      });
    }
    return str;
  };

  window.applyI18n = function (root) {
    root = root || document;
    root.querySelectorAll('[data-i18n]').forEach(el => {
      el.textContent = window.t(el.getAttribute('data-i18n'));
    });
    root.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
      el.placeholder = window.t(el.getAttribute('data-i18n-placeholder'));
    });
    root.querySelectorAll('[data-i18n-title]').forEach(el => {
      el.title = window.t(el.getAttribute('data-i18n-title'));
    });
  };

  async function persistLanguagePreference(lang) {
    try {
      if (!window._supabase) return;
      const { data: { session } } = await window._supabase.auth.getSession();
      if (!session) return;
      await window._supabase.from('company_profile').update({ language: lang }).eq('id', session.user.id);
    } catch (err) {
      console.error('Error saving language preference:', err);
    }
  }

  window.setLanguage = function (lang) {
    if (lang !== 'es' && lang !== 'en') return;
    window.currentLang = lang;
    localStorage.setItem('dotacian_lang', lang);
    document.documentElement.lang = lang;
    window.applyI18n();
    if (typeof window.onLanguageChanged === 'function') window.onLanguageChanged(lang);
    persistLanguagePreference(lang);
  };

  // Si utils.js ya conoce el idioma guardado en company_profile (más
  // autoritativo que localStorage), lo aplica cuando llegue.
  window.addEventListener('userProfileLoaded', (e) => {
    const lang = e.detail && e.detail.language;
    if (lang && (lang === 'es' || lang === 'en') && lang !== window.currentLang) {
      window.currentLang = lang;
      localStorage.setItem('dotacian_lang', lang);
      document.documentElement.lang = lang;
      window.applyI18n();
      if (typeof window.onLanguageChanged === 'function') window.onLanguageChanged(lang);
    }
  });

  document.addEventListener('DOMContentLoaded', () => {
    document.documentElement.lang = window.currentLang;
    window.applyI18n();
  });
})();
