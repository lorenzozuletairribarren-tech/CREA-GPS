const { ROLE, canAccessSensitiveFields } = require('../types/roles');

async function fetchJson(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Error al obtener datos: ${response.status}`);
  }
  return response.json();
}

/**
 * Evita pedir datos clínicos al backend cuando el rol no corresponde.
 */
async function getPatientRecordByRole(patientId, role) {
  if (canAccessSensitiveFields(role)) {
    return fetchJson(`/api/clinical/patients/${patientId}/detail`);
  }

  if (role === ROLE.RECEPCION) {
    return fetchJson(`/api/reception/patients/${patientId}/summary`);
  }

  throw new Error('Rol no autorizado');
}

module.exports = { getPatientRecordByRole };
