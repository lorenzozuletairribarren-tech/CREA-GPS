# Automatizaciones críticas · CREA Arica

## Objetivo
Cubrir confirmaciones, recordatorios, generación/publicación de PDF y descargas seguras en portal con auditoría y manejo de errores.

## Diagrama breve: disparadores -> función -> tablas

| Disparador | Función | Tablas afectadas |
|---|---|---|
| Cron diario 18:00 (hora Chile, `pg_cron`) | `run_daily_automation_confirmations()` -> `queue_next_day_confirmations()` | `automation_job_runs`, `appointment_confirmations`, `audit_log` |
| Job de recordatorios (24h / 2h) | `queue_session_reminders(hours_before)` | `appointment_reminders`, `audit_log` |
| Publicar informe/ficha a portal | `publish_generated_document(target_document, publisher)` | `generated_documents`, `audit_log` |
| Descarga desde portal | `portal_download_generated_document(target_document, ip, ua)` | `portal_download_audit`, `audit_log` |

## Flujo 1: Confirmación día siguiente
1. A las 18:00 CL se ejecuta `run_daily_automation_confirmations()`.
2. Se crea corrida en `automation_job_runs`.
3. Se generan pendientes en `appointment_confirmations` para citas de mañana (WhatsApp/email).
4. Se registra resultado o error (`OK/ERROR`) y detalles en `audit_log`.

## Flujo 2: Recordatorios 24h y 2h
1. Un worker/cron ejecuta `queue_session_reminders(24)` y `queue_session_reminders(2)`.
2. Se insertan pendientes únicos en `appointment_reminders` por cita/canal/tipo.
3. Se deja trazabilidad en `audit_log`.

## Flujo 3: PDF y publicación
1. El profesional/supervisor genera y luego publica documento con `publish_generated_document(...)`.
2. Se completa `pdf_storage_path` y se marca `is_published=true`.
3. Solo documentos publicados y `visibility='PORTAL'` son visibles en portal.

## Flujo 4: Portal seguro + auditoría
1. El apoderado solicita descarga usando `portal_download_generated_document(...)`.
2. La función valida:
   - documento publicado,
   - visibilidad portal,
   - acceso al paciente (`can_access_patient`).
3. Se registra descarga en `portal_download_audit` y evento en `audit_log`.

## Manejo de errores y logs
- `run_daily_automation_confirmations()` encapsula errores y guarda `error_message`.
- Cada automatización deja evento estructurado en `audit_log`.
- Las funciones de portal lanzan error explícito cuando no hay autorización o publicación.
