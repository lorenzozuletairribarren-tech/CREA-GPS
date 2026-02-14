const React = require('react');
const { canAccessSensitiveFields } = require('../types/roles');

function ClinicalRecordEditor({ role, record, onChange }) {
  const canEditSensitive = canAccessSensitiveFields(role);

  return React.createElement(
    'section',
    null,
    canEditSensitive
      ? React.createElement(
          'div',
          {
            style: {
              backgroundColor: '#fff4e5',
              border: '1px solid #ffcc80',
              color: '#7a4b00',
              padding: '10px',
              borderRadius: '6px',
              marginBottom: '12px',
              fontWeight: '600',
            },
            role: 'alert',
          },
          'Solo clínicos: estás editando datos sensibles.',
        )
      : null,
    canEditSensitive
      ? React.createElement('textarea', {
          value: record.notas_clinicas || '',
          onChange: (event) => onChange('notas_clinicas', event.target.value),
          placeholder: 'Notas clínicas',
          rows: 6,
        })
      : React.createElement(
          'p',
          { style: { color: '#555' } },
          'No tienes permisos para editar notas clínicas.',
        ),
  );
}

module.exports = { ClinicalRecordEditor };
