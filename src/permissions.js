export const modulePermissions = {
  GERENTE_ADMIN: ['*'],
  RECEPCION_ADMIN: ['Recepcion', 'Informes', 'PortalPaciente', 'CredencialesPermisos'],
  PROFESIONAL_CLINICO: ['AtencionClinica', 'Evaluacion', 'FichaClinica', 'Informes'],
  SUPERVISOR_CLINICO: ['Recepcion', 'AtencionClinica', 'Evaluacion', 'FichaClinica', 'Informes'],
  PACIENTE_APODERADO: ['PortalPaciente']
};

export function canViewModule(role, moduleKey) {
  const allowed = modulePermissions[role] || [];
  return allowed.includes('*') || allowed.includes(moduleKey);
}
