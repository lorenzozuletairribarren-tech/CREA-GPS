# CREA Arica · App operativa (base segura)

Implementación inicial funcional para operación administrativa + clínica + portal paciente/apoderado.

## Incluye
- Menú lateral con 8 módulos obligatorios.
- Visualización por rol (Gerente, Recepción, Profesional, Supervisor, Paciente/Apoderado).
- Recepción con check-in, pagos en CLP y `BONO_FONASA`.
- Detección de conflicto horario por profesional (lógica compartida + pruebas).
- Base documental de arquitectura y esquema SQL con RLS en `db/schema.sql`.
- Documento de automatizaciones críticas en `docs/automatizaciones-criticas.md`.

## Automatizaciones críticas implementadas (modelo SQL)
- Confirmación día siguiente por cron 18:00 CL.
- Recordatorios 24h y 2h.
- Publicación de PDF y control de descarga portal solo para documentos publicados.
- Auditoría de descargas y corridas de jobs.

## Ejecutar validaciones
```bash
npm run lint
npm run test
npm run build
```

## Ejecutar app
Por restricción del entorno (sin instalar dependencias npm externas), esta versión funciona como SPA estática:
1. Abrir `index.html` en navegador, o
2. Servir la carpeta con cualquier servidor estático.
