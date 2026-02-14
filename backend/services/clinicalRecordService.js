const ROLE = {
  RECEPCION: 'recepcion',
  CLINICO: 'clinico',
};

const RECEPTION_FIELDS = [
  'id',
  'nombre',
  'contacto',
  'agenda',
  'asistencia',
  'estado',
  'pago',
];

const CLINICAL_FIELDS = [
  ...RECEPTION_FIELDS,
  'notas_clinicas',
  'evaluaciones_detalladas',
  'diagnosticos',
];

function getViewNameByRole(role) {
  if (role === ROLE.CLINICO) return 'vw_paciente_clinico';
  return 'vw_paciente_recepcion';
}

function getAllowedFieldsByRole(role) {
  return role === ROLE.CLINICO ? CLINICAL_FIELDS : RECEPTION_FIELDS;
}

function sanitizeByRole(record, role) {
  const allowed = new Set(getAllowedFieldsByRole(role));
  return Object.fromEntries(
    Object.entries(record).filter(([key]) => allowed.has(key)),
  );
}

/**
 * queryFn esperado: async (sql, params) => [{...}]
 */
async function fetchPatientRecordByRole({ queryFn, patientId, role }) {
  const viewName = getViewNameByRole(role);
  const rows = await queryFn(
    `SELECT * FROM ${viewName} WHERE id = $1 LIMIT 1`,
    [patientId],
  );

  if (!rows.length) return null;
  return sanitizeByRole(rows[0], role);
}

module.exports = {
  ROLE,
  fetchPatientRecordByRole,
  getAllowedFieldsByRole,
  getViewNameByRole,
  sanitizeByRole,
};
