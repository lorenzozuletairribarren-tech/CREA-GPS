import { appointments, modules, payments, portalDocs, roleLabels } from './data.js';
import { canViewModule } from './permissions.js';
import { formatCLP, hasConflict } from './utils/schedule.js';

const state = {
  role: 'GERENTE_ADMIN',
  selectedModule: 'Recepcion'
};

function recepcionView() {
  const conflicto = hasConflict(appointments, {
    profesional: 'Terapeuta Paula',
    inicio: '2026-02-15T09:30:00-03:00',
    fin: '2026-02-15T10:15:00-03:00'
  });

  return `
    <h2>Recepción</h2>
    <p>Agenda, check-in, cobros y confirmaciones automáticas.</p>
    <div class="kpi-grid">
      <div class="card"><strong>Choque de horario</strong><span>${conflicto ? 'Detectado' : 'Sin conflicto'}</span></div>
      <div class="card"><strong>Confirmación día siguiente</strong><span>Programada por WhatsApp + Email</span></div>
    </div>
    <h3>Check-in del día</h3>
    <ul>${appointments.map((a) => `<li>${a.id} · ${a.paciente} · ${a.estadoCheckin}</li>`).join('')}</ul>
    <h3>Pagos</h3>
    <ul>${payments.map((p) => `<li>${p.paciente}: ${formatCLP(p.montoCLP)} (${p.medio}) - ${p.estado}</li>`).join('')}</ul>
  `;
}

function clinicaView() {
  return `
    <h2>Atención clínica</h2>
    <p>Sesiones individuales/grupales, notas clínicas y plan terapéutico.</p>
    <ul>
      <li>Sesión INDIVIDUAL · Sofia R. · Nota: BORRADOR</li>
      <li>Sesión GRUPAL · Habilidades Sociales · Nota: FINALIZADA</li>
    </ul>
  `;
}

function evaluacionView() {
  return '<h2>Evaluación</h2><p>Instrumentos, resultados, interpretación y recomendaciones.</p>';
}

function fichaView() {
  return '<h2>Ficha clínica</h2><p>Historia única, diagnósticos y documentos asociados.</p>';
}

function informesView() {
  return '<h2>Informes</h2><p>Plantillas, aprobación clínica y exportación PDF.</p>';
}

function credencialesView() {
  return '<h2>Credenciales y permisos</h2><p>Invitaciones, roles y auditoría de acciones.</p>';
}

function rrhhView() {
  return '<h2>RRHH</h2><p>Fichas de personal, documentos y solicitudes internas.</p>';
}

function portalView() {
  return `
    <h2>Portal Paciente/Apoderado</h2>
    <p>Descarga de informes y solicitudes de documentos.</p>
    <ul>${portalDocs.map((d) => `<li>${d.titulo} (${d.fecha})</li>`).join('')}</ul>
  `;
}

const viewByModule = {
  Recepcion: recepcionView,
  AtencionClinica: clinicaView,
  Evaluacion: evaluacionView,
  FichaClinica: fichaView,
  Informes: informesView,
  CredencialesPermisos: credencialesView,
  RRHH: rrhhView,
  PortalPaciente: portalView
};

function firstAllowedModuleKey(role) {
  const firstModule = modules.find((moduleEntry) => canViewModule(role, moduleEntry.key));
  return firstModule ? firstModule.key : 'PortalPaciente';
}

function render() {
  const app = document.querySelector('#app');
  if (!canViewModule(state.role, state.selectedModule)) {
    state.selectedModule = firstAllowedModuleKey(state.role);
  }

  const moduleButtons = modules
    .filter((moduleEntry) => canViewModule(state.role, moduleEntry.key))
    .map(
      (moduleEntry) =>
        `<button class="menu-btn ${state.selectedModule === moduleEntry.key ? 'active' : ''}" data-module-key="${moduleEntry.key}">${moduleEntry.label}</button>`
    )
    .join('');

  app.innerHTML = `
    <aside>
      <h1>CREA Arica</h1>
      <label>Rol
        <select id="role-select">
          ${Object.entries(roleLabels)
            .map(([key, label]) => `<option value="${key}" ${key === state.role ? 'selected' : ''}>${label}</option>`)
            .join('')}
        </select>
      </label>
      <nav>${moduleButtons}</nav>
    </aside>
    <main>
      ${viewByModule[state.selectedModule]()}
    </main>
  `;

  app.querySelector('#role-select').addEventListener('change', (event) => {
    state.role = event.target.value;
    render();
  });

  app.querySelectorAll('.menu-btn').forEach((button) => {
    button.addEventListener('click', () => {
      state.selectedModule = button.dataset.moduleKey;
      render();
    });
  });
}

render();
