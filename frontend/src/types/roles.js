const ROLE = {
  RECEPCION: 'recepcion',
  CLINICO: 'clinico',
};

function canAccessSensitiveFields(role) {
  return role === ROLE.CLINICO;
}

module.exports = { ROLE, canAccessSensitiveFields };
