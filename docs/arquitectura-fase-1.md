# CREA Arica · Entrega 1

Primera entrega enfocada en:
1. Modelo de datos integral.
2. Relaciones entre módulos administrativos, clínicos y portal.
3. Reglas de permisos por rol mediante RLS.
4. Estructura de navegación (menú lateral) y flujos base.

## 1) Mapa de módulos (menú lateral)

1. **Recepción**
   - Agenda diaria/semanal.
   - Check-in (estados: llegó, en espera, en sesión, finalizó, ausente, justificado).
   - Cobros/pagos (CLP + bono/FONASA).
   - Confirmaciones automáticas (WhatsApp/email).
   - Gestión de pre-admisiones.

2. **Atención clínica**
   - Sesiones clínicas (individuales y grupales).
   - Notas clínicas.
   - Plan terapéutico.
   - Tareas para hogar/apoderado.

3. **Evaluación**
   - Instrumentos de evaluación.
   - Resultados.
   - Interpretación clínica.
   - Recomendaciones.

4. **Ficha clínica**
   - Ficha única del paciente.
   - Historia clínica y diagnósticos.
   - Alertas, medicación y documentos adjuntos.

5. **Informes**
   - Plantillas.
   - Generación automática de certificados/informes.
   - Flujo de aprobación/firma.
   - Exportación PDF + publicación en portal/descarga.

6. **Credenciales y permisos**
   - Usuarios.
   - Roles.
   - Invitaciones y acceso controlado.
   - Auditoría de acciones.

7. **RRHH**
   - Fichas de personal.
   - Documentos laborales.
   - Solicitudes internas.

8. **Portal Paciente/Apoderado**
   - Visualización acotada de datos.
   - Descarga de informes autorizados.
   - Solicitud de documentos.

## 2) Modelo de datos (resumen funcional)

El modelo detallado está en `db/schema.sql`.

### Núcleo de identidad y seguridad
- `users_profile`, `user_roles`, `user_invitations`, `audit_log`.
- Acceso por invitación con estado (`PENDIENTE`, `ACEPTADA`, etc.).
- Rol obligatorio por usuario.

### Paciente y admisión
- `people`, `patients`, `patient_guardians`, `pre_admissions`.
- Un paciente se asocia a una persona (`patients.person_id`).
- Un paciente puede tener varios apoderados.

### Agenda y recepción
- `professional_availability`, `appointments`, `appointment_professionals`, `group_session_participants`, `checkins`, `payments`, `appointment_confirmations`.
- Soporta sesiones individuales y grupales.
- Control de choques de horario mediante trigger.
- Confirmaciones por WhatsApp/email quedan registradas.

### Clínica y evaluación
- `patient_records`, `therapy_plans`, `clinical_sessions`, `home_tasks`, `assessment_instruments`, `assessment_results`.
- Ficha única clínica por paciente.
- Sesión clínica vinculable a una cita.

### Informes y documentos
- `document_templates`, `generated_documents`, `patient_documents`.
- Visibilidad de documentos por tipo: `INTERNO`, `CLINICO`, `PORTAL`.

### RRHH + Portal
- RRHH: `staff_profiles`, `staff_documents`, `internal_requests`.
- Portal: `portal_requests`.

## 3) Relaciones clave

- **Usuario ↔ Rol:** `user_roles.user_id -> users_profile.id` (N:N simplificada por múltiples filas).
- **Paciente ↔ Persona:** `patients.person_id -> people.id` (1:1).
- **Paciente ↔ Apoderado:** `patient_guardians` (N:N).
- **Cita ↔ Profesional:** `appointment_professionals` (N:N).
- **Cita grupal ↔ Pacientes:** `group_session_participants` (N:N).
- **Cita ↔ Check-in:** `checkins.appointment_id` único (1:1).
- **Paciente ↔ Pago:** `payments.patient_id` (1:N).
- **Paciente ↔ Sesión clínica:** `clinical_sessions.patient_id` (1:N).
- **Paciente ↔ Ficha clínica:** `patient_records.patient_id` único (1:1).
- **Paciente ↔ Informes/documentos:** `generated_documents`, `patient_documents` (1:N).

## 4) Matriz de permisos (RLS)

Implementada en SQL con funciones auxiliares:
- `current_user_profile_id()`
- `has_role(role)`
- `is_admin()`
- `is_supervisor_or_admin()`
- `can_access_patient(patient_id)`

### Rol: Gerente/Administrador
- Acceso total administrativo, clínico, RRHH, permisos, invitaciones y auditoría.
- Puede gestionar cualquier registro.

### Rol: Recepción/Administrativo
- Agenda, check-in, cobros y pre-admisión.
- Sin permisos de edición clínica profunda.
- Puede leer información mínima operativa de clínica cuando es necesaria para la agenda.

### Rol: Profesional Clínico
- Accede solo a sus sesiones y pacientes relacionados.
- Puede editar notas/sesiones/evaluaciones de su ámbito.
- Ve pagos en modo lectura.

### Rol: Supervisor Clínico
- Acceso clínico completo (todos los pacientes/sesiones/evaluaciones).
- Puede aprobar/firmar informes según flujo interno.

### Rol: Paciente/Apoderado
- Solo portal.
- Lectura limitada de información autorizada.
- Descarga de informes/documentos con `visibility='PORTAL'`.
- Puede crear solicitudes en portal.

## 5) Reglas de negocio críticas cubiertas

1. **Detección de choques de horario por profesional**
   - Trigger `trg_prevent_overlapping_appointments` con validación por traslape de rangos.

2. **Disponibilidad por profesional**
   - Tabla `professional_availability` + cruces con `appointments`.

3. **Sesiones individuales y grupales**
   - `appointments.appointment_type` + `group_session_participants`.

4. **Estados de check-in requeridos**
   - Enum `checkin_status` con todos los estados solicitados.

5. **Pagos en CLP + bono/FONASA**
   - `payments.amount_clp` + `payment_method='BONO_FONASA'`.

6. **Generación de informes/certificados por plantilla**
   - `document_templates` + `generated_documents`.

7. **Confirmación automática agenda día siguiente**
   - `appointment_confirmations` lista para registrar jobs automáticos por canal.

8. **Pre-admisión pública + gestión interna**
   - `pre_admissions` con RLS de inserción pública y gestión por recepción/admin.

## 6) Flujo de navegación propuesto

- **Inicio (dashboard)**
  - Widgets por rol: próximas sesiones, check-ins pendientes, pagos del día, tareas clínicas.

- **Recepción**
  - Agenda → detalle cita → check-in → pago → confirmación.
  - Pre-admisión → revisión → conversión a paciente.

- **Atención clínica**
  - Mis sesiones → nota clínica → tareas → actualización plan.

- **Evaluación**
  - Selección instrumento → carga puntajes → interpretación → recomendaciones.

- **Ficha clínica**
  - Vista longitudinal de historia, diagnósticos, documentos y alertas.

- **Informes**
  - Elegir plantilla → autocompletar con datos del paciente → revisión/firmas → exportar/publicar.

- **Credenciales y permisos**
  - Invitar usuario → asignar rol → activar/desactivar → revisar auditoría.

- **RRHH**
  - Fichas de personal → documentos → solicitudes internas.

- **Portal Apoderado**
  - Mis niños → documentos/informes autorizados → solicitudes.

---

## Siguiente entrega sugerida
1. API (REST o GraphQL) sobre este esquema.
2. Jobs automáticos (confirmaciones WhatsApp/email y generación PDF).
3. Front-end con menú lateral por rol y pantallas iniciales por módulo.
4. Seeds iniciales (roles, plantillas base, instrumentos frecuentes).
