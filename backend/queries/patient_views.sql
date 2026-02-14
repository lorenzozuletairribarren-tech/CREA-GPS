-- Vistas separadas por rol para proteger datos sensibles.

CREATE OR REPLACE VIEW vw_paciente_recepcion AS
SELECT
  p.id,
  p.nombre,
  p.telefono AS contacto,
  c.fecha AS agenda,
  c.asistencia,
  c.estado,
  c.pago
FROM pacientes p
JOIN citas c ON c.paciente_id = p.id;

CREATE OR REPLACE VIEW vw_paciente_clinico AS
SELECT
  p.id,
  p.nombre,
  p.telefono AS contacto,
  c.fecha AS agenda,
  c.asistencia,
  c.estado,
  c.pago,
  h.notas_clinicas,
  h.evaluaciones_detalladas,
  h.diagnosticos
FROM pacientes p
JOIN citas c ON c.paciente_id = p.id
LEFT JOIN historias_clinicas h ON h.paciente_id = p.id;

-- Permisos sugeridos: recepción solo sobre vista limitada.
GRANT SELECT ON vw_paciente_recepcion TO role_recepcion;
REVOKE ALL ON vw_paciente_clinico FROM role_recepcion;
GRANT SELECT ON vw_paciente_clinico TO role_clinico;
