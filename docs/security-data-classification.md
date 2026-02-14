# Clasificación de datos clínicos sensibles

## Niveles de sensibilidad

| Campo | Nivel | Razón | Rol permitido |
| --- | --- | --- | --- |
| `NotasClinicas` | Alto (PHI) | Contiene narrativas de salud mental/física y evolución de tratamiento. | `clinico` |
| `EvaluacionesDetalladas` | Alto (PHI) | Incluye puntajes, observaciones y anexos clínicos completos. | `clinico` |
| `Diagnosticos` | Alto (PHI) | Identifica condición médica y riesgo de discriminación. | `clinico` |
| `Asistencia` | Medio | Dato operativo no clínico, pero asociado al paciente. | `recepcion`, `clinico` |
| `Agenda` | Medio | Horarios de atención, necesario para operación diaria. | `recepcion`, `clinico` |
| `Estado` | Medio | Estado administrativo de atención. | `recepcion`, `clinico` |
| `Pago` | Medio | Información administrativa de cobranza. | `recepcion`, `clinico` |
| `Contacto` | Medio | Comunicación y coordinación de citas. | `recepcion`, `clinico` |

## Reglas de control de acceso

1. **Separación de vistas por rol:** recepción y clínico consultan endpoints y vistas de DB distintas.
2. **Principio de mínimo privilegio:** recepción nunca recibe columnas clínicas en payload.
3. **Defensa en profundidad:** filtrado de columnas tanto en base de datos como en backend y frontend.
4. **Trazabilidad:** cualquier intento de acceso a campos sensibles por rol no autorizado debe ser bloqueado y auditado.
