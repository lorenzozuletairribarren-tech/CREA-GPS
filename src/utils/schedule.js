export function hasConflict(existingAppointments, newAppointment) {
  return existingAppointments.some((item) => {
    if (item.profesional !== newAppointment.profesional) {
      return false;
    }
    const aStart = new Date(item.inicio).getTime();
    const aEnd = new Date(item.fin).getTime();
    const bStart = new Date(newAppointment.inicio).getTime();
    const bEnd = new Date(newAppointment.fin).getTime();
    return aStart < bEnd && bStart < aEnd;
  });
}

export function formatCLP(value) {
  return new Intl.NumberFormat('es-CL', { style: 'currency', currency: 'CLP', maximumFractionDigits: 0 }).format(value);
}
