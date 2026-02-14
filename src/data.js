export const modules = [
  { key: 'Recepcion', label: 'Recepción' },
  { key: 'AtencionClinica', label: 'Atención clínica' },
  { key: 'Evaluacion', label: 'Evaluación' },
  { key: 'FichaClinica', label: 'Ficha clínica' },
  { key: 'Informes', label: 'Informes' },
  { key: 'CredencialesPermisos', label: 'Credenciales y permisos' },
  { key: 'RRHH', label: 'RRHH' },
  { key: 'PortalPaciente', label: 'Portal Paciente' }
];

export const roleLabels = {
  GERENTE_ADMIN: 'Gerente/Administrador',
  RECEPCION_ADMIN: 'Recepción/Administrativo',
  PROFESIONAL_CLINICO: 'Profesional Clínico',
  SUPERVISOR_CLINICO: 'Supervisor Clínico',
  PACIENTE_APODERADO: 'Paciente/Apoderado'
};

export const appointments = [
  {
    id: 'A-1001',
    paciente: 'Sofia R.',
    profesional: 'Terapeuta Paula',
    inicio: '2026-02-15T09:00:00-03:00',
    fin: '2026-02-15T09:45:00-03:00',
    tipo: 'INDIVIDUAL',
    estadoCheckin: 'LLEGO'
  },
  {
    id: 'A-1002',
    paciente: 'Grupo Habilidades Sociales',
    profesional: 'Terapeuta Paula',
    inicio: '2026-02-15T10:00:00-03:00',
    fin: '2026-02-15T11:00:00-03:00',
    tipo: 'GRUPAL',
    estadoCheckin: 'EN_ESPERA'
  }
];

export const payments = [
  { id: 'P-1', paciente: 'Sofia R.', montoCLP: 28000, medio: 'BONO_FONASA', estado: 'PAGADO' },
  { id: 'P-2', paciente: 'Mateo V.', montoCLP: 32000, medio: 'TRANSFERENCIA', estado: 'PENDIENTE' }
];

export const portalDocs = [
  { id: 'D-1', titulo: 'Informe Integracion Sensorial', visible: true, fecha: '2026-02-10' },
  { id: 'D-2', titulo: 'Certificado de atencion', visible: true, fecha: '2026-02-11' }
];
