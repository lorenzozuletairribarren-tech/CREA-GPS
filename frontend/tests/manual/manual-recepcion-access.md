# Prueba manual: recepción no accede a datos clínicos sensibles

## Precondiciones
- Usuario autenticado con rol `recepcion`.
- Existe al menos un paciente con `notas_clinicas` y `evaluaciones_detalladas` cargadas.

## Pasos
1. Iniciar sesión como recepción.
2. Abrir vista de paciente desde agenda.
3. Verificar en red (DevTools) que el frontend llama solo a:
   - `GET /api/reception/patients/:id/summary`
4. Confirmar que **no** se llama a:
   - `GET /api/clinical/patients/:id/detail`
5. Inspeccionar payload de respuesta y validar ausencia de campos:
   - `notas_clinicas`
   - `evaluaciones_detalladas`
   - `diagnosticos`
6. Intentar acceder manualmente al endpoint clínico con sesión de recepción.

## Resultado esperado
- La API clínica responde `403` para recepción.
- El payload de summary nunca contiene datos clínicos sensibles.
- La UI no muestra controles de edición de notas clínicas.
