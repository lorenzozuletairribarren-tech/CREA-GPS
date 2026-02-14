# Esquema de Base de Datos (clínica/centro terapéutico)

> Motor sugerido: **PostgreSQL 15+**.
> Convenciones: claves primarias `uuid`, timestamps `timestamptz`, soft-delete con `deleted_at` donde aplique.

## 1) Diccionario de tablas con campos y tipos

### 1.1 Seguridad y usuarios

#### `usuarios`
- `id uuid pk`
- `base44_user_id text unique not null` (id externo de autenticación)
- `email citext unique not null`
- `is_active boolean not null default true`
- `last_login_at timestamptz null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null` (fk a `usuarios.id`)
- `deleted_at timestamptz null`

#### `perfil_usuario`
- `id uuid pk`
- `usuario_id uuid unique not null` (fk `usuarios.id`)
- `nombre text not null`
- `apellido text not null`
- `telefono text null`
- `firma_url text null`
- `estado_usuario text not null` (ej: `activo`, `suspendido`, `bloqueado`)
- `rol_primario_id uuid null` (fk `roles.id`, opcional si se usa RBAC nativo)
- `metadata jsonb not null default '{}'::jsonb`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null` (fk a `usuarios.id`)
- `deleted_at timestamptz null`

#### `roles`
- `id uuid pk`
- `codigo text unique not null` (ej: `admin`, `recepcion`, `profesional`)
- `nombre text not null`
- `descripcion text null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`

#### `permisos`
- `id uuid pk`
- `codigo text unique not null` (ej: `sesiones.read`, `notas.write`)
- `nombre text not null`
- `descripcion text null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`

#### `rol_permiso`
- `rol_id uuid not null` (fk `roles.id`)
- `permiso_id uuid not null` (fk `permisos.id`)
- `created_at timestamptz not null default now()`
- `created_by uuid null`
- `pk (rol_id, permiso_id)`

#### `usuario_rol`
- `usuario_id uuid not null` (fk `usuarios.id`)
- `rol_id uuid not null` (fk `roles.id`)
- `created_at timestamptz not null default now()`
- `created_by uuid null`
- `pk (usuario_id, rol_id)`

---

### 1.2 Pacientes, responsables y profesionales

#### `pacientes`
- `id uuid pk`
- `nombres text not null`
- `apellidos text not null`
- `rut text null unique` (opcional, validar formato en app)
- `fecha_nacimiento date null`
- `sexo text null`
- `direccion text null`
- `comuna text null`
- `colegio text null`
- `observaciones text null`
- `estado_paciente text not null default 'activo'`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`
- `deleted_at timestamptz null`

#### `responsables`
- `id uuid pk`
- `nombres text not null`
- `apellidos text not null`
- `rut text null unique`
- `email citext null`
- `telefono text null`
- `direccion text null`
- `parentesco text null`
- `es_contacto_principal boolean not null default false`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`
- `deleted_at timestamptz null`

#### `paciente_responsable`
- `paciente_id uuid not null` (fk `pacientes.id`)
- `responsable_id uuid not null` (fk `responsables.id`)
- `tipo_relacion text null` (madre, padre, tutor, etc.)
- `autorizado_retiro boolean not null default false`
- `autorizado_info_clinica boolean not null default false`
- `created_at timestamptz not null default now()`
- `created_by uuid null`
- `pk (paciente_id, responsable_id)`

#### `disciplinas_servicios`
- `id uuid pk`
- `codigo text unique not null` (ej: `TO`, `FONO`, `PSI`, `PSP`)
- `nombre text not null`
- `descripcion text null`
- `duracion_min_default int null`
- `arancel_base numeric(12,2) null`
- `activo boolean not null default true`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`

#### `profesionales`
- `id uuid pk`
- `usuario_id uuid unique null` (fk `usuarios.id`, si tiene login)
- `nombres text not null`
- `apellidos text not null`
- `disciplina_id uuid not null` (fk `disciplinas_servicios.id`)
- `registro_profesional text null`
- `jornada jsonb null` (disponibilidad semanal)
- `color_agenda text null` (hex)
- `activo boolean not null default true`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`
- `deleted_at timestamptz null`

---

### 1.3 Admisión, sesiones y operación clínica

#### `preadmisiones`
- `id uuid pk`
- `paciente_id uuid null` (fk `pacientes.id`, puede crearse luego)
- `nombre_contacto text not null`
- `telefono_contacto text null`
- `email_contacto citext null`
- `edad_referencial int null`
- `motivo_consulta text null`
- `disciplina_interes_id uuid null` (fk `disciplinas_servicios.id`)
- `estado_pipeline text not null` (`nueva`, `contactado`, `entrevista`, `evaluacion`, `admitido`, `rechazado`)
- `fecha_estado timestamptz not null default now()`
- `notas text null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`
- `deleted_at timestamptz null`

#### `grupos`
- `id uuid pk`
- `nombre text not null`
- `disciplina_id uuid null` (fk `disciplinas_servicios.id`)
- `descripcion text null`
- `activo boolean not null default true`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`
- `deleted_at timestamptz null`

#### `grupo_miembros`
- `grupo_id uuid not null` (fk `grupos.id`)
- `paciente_id uuid not null` (fk `pacientes.id`)
- `fecha_ingreso date not null default current_date`
- `fecha_egreso date null`
- `created_at timestamptz not null default now()`
- `created_by uuid null`
- `pk (grupo_id, paciente_id)`

#### `sesiones`
- `id uuid pk`
- `profesional_id uuid not null` (fk `profesionales.id`)
- `disciplina_id uuid not null` (fk `disciplinas_servicios.id`)
- `paciente_id uuid null` (fk `pacientes.id`, sesión individual)
- `grupo_id uuid null` (fk `grupos.id`, sesión grupal)
- `fecha_inicio timestamptz not null`
- `fecha_fin timestamptz not null`
- `estado_sesion text not null` (`agendada`, `confirmada`, `en_curso`, `realizada`, `ausente`, `cancelada`)
- `modalidad text null` (`presencial`, `online`, `domicilio`)
- `lugar_sala text null`
- `observacion_operativa text null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`
- `deleted_at timestamptz null`

> Regla recomendada: check para exigir **exactamente uno** entre `paciente_id` o `grupo_id`.

#### `check_in`
- `id uuid pk`
- `sesion_id uuid unique not null` (fk `sesiones.id`)
- `hora_llegada timestamptz null`
- `estado_checkin text not null` (`pendiente`, `llego`, `no_llego`, `tarde`)
- `notas_recepcion text null`
- `registrado_por uuid null` (fk `usuarios.id`)
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

#### `pagos`
- `id uuid pk`
- `paciente_id uuid not null` (fk `pacientes.id`)
- `sesion_id uuid null` (fk `sesiones.id`)
- `tipo_pago text not null` (`particular`, `bono_fonasa`, `isapre`, `paquete`)
- `monto numeric(12,2) not null`
- `moneda char(3) not null default 'CLP'`
- `fecha_pago date not null`
- `medio_pago text not null` (`efectivo`, `transferencia`, `tarjeta`, `webpay`)
- `referencia text null`
- `estado_pago text not null default 'pagado'`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`
- `deleted_at timestamptz null`

---

### 1.4 Registro clínico

#### `planes_terapeuticos`
- `id uuid pk`
- `paciente_id uuid not null` (fk `pacientes.id`)
- `profesional_responsable_id uuid not null` (fk `profesionales.id`)
- `disciplina_id uuid null` (fk `disciplinas_servicios.id`)
- `objetivos text not null`
- `frecuencia_sugerida text null`
- `fecha_inicio date not null`
- `fecha_revision date null`
- `estado_plan text not null default 'activo'`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`
- `deleted_at timestamptz null`

#### `notas_clinicas`
- `id uuid pk`
- `sesion_id uuid not null` (fk `sesiones.id`)
- `profesional_id uuid not null` (fk `profesionales.id`)
- `estructura text not null default 'SOAP'`
- `subjetivo text null`
- `objetivo text null`
- `analisis text null`
- `plan text null`
- `confidencialidad text not null default 'clinico_interno'`
- `firmado_at timestamptz null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`
- `deleted_at timestamptz null`

#### `instrumentos_tests`
- `id uuid pk`
- `codigo text unique not null`
- `nombre text not null`
- `tipo text null`
- `descripcion text null`
- `escala_resultado text null`
- `activo boolean not null default true`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`

#### `plantillas_instrumento`
- `id uuid pk`
- `instrumento_id uuid not null` (fk `instrumentos_tests.id`)
- `nombre text not null`
- `version text null`
- `estructura jsonb not null`
- `activo boolean not null default true`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`

#### `evaluaciones`
- `id uuid pk`
- `paciente_id uuid not null` (fk `pacientes.id`)
- `profesional_id uuid not null` (fk `profesionales.id`)
- `instrumento_id uuid null` (fk `instrumentos_tests.id`)
- `sesion_id uuid null` (fk `sesiones.id`)
- `fecha_evaluacion date not null`
- `resultado_resumen text null`
- `resultado_detalle jsonb null`
- `interpretacion text null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`
- `deleted_at timestamptz null`

#### `informes`
- `id uuid pk`
- `paciente_id uuid not null` (fk `pacientes.id`)
- `profesional_id uuid not null` (fk `profesionales.id`)
- `tipo_informe text not null` (`clinico`, `escolar`, `certificado`, `constancia`)
- `estado_informe text not null` (`borrador`, `aprobado`, `firmado`, `entregado`)
- `contenido text null`
- `pdf_url text null`
- `firmado_at timestamptz null`
- `visible_portal boolean not null default false`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`
- `deleted_at timestamptz null`

#### `solicitudes_portal`
- `id uuid pk`
- `paciente_id uuid not null` (fk `pacientes.id`)
- `responsable_id uuid null` (fk `responsables.id`)
- `tipo_solicitud text not null` (`informe`, `certificado`, `constancia`, `otro`)
- `detalle text null`
- `estado_solicitud text not null` (`nueva`, `en_revision`, `resuelta`, `rechazada`)
- `respuesta text null`
- `respondido_por uuid null` (fk `usuarios.id`)
- `respondido_at timestamptz null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`
- `deleted_at timestamptz null`

---

### 1.5 Archivos y auditoría

#### `archivos_adjuntos`
- `id uuid pk`
- `entidad_tipo text not null` (ej: `paciente`, `sesion`, `informe`, `evaluacion`)
- `entidad_id uuid not null`
- `origen text not null` (`drive`, `upload`)
- `nombre_archivo text not null`
- `mime_type text null`
- `tamano_bytes bigint null`
- `storage_url text not null`
- `checksum_sha256 text null`
- `nivel_permiso text not null default 'interno'` (`interno`, `profesional`, `portal_familia`)
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `created_by uuid null`
- `deleted_at timestamptz null`

#### `auditoria_acceso`
- `id uuid pk`
- `usuario_id uuid not null` (fk `usuarios.id`)
- `accion text not null` (`view`, `download`, `create`, `update`, `delete`)
- `entidad_tipo text not null`
- `entidad_id uuid not null`
- `ip inet null`
- `user_agent text null`
- `detalle jsonb null`
- `created_at timestamptz not null default now()`

## 2) Relaciones (1-N, N-N)

### 1 a N
- `usuarios` 1—N `auditoria_acceso`
- `usuarios` 1—N `archivos_adjuntos` (via `created_by`)
- `usuarios` 1—1 `perfil_usuario`
- `disciplinas_servicios` 1—N `profesionales`
- `disciplinas_servicios` 1—N `sesiones`
- `disciplinas_servicios` 1—N `preadmisiones`
- `pacientes` 1—N `sesiones` (solo individuales)
- `grupos` 1—N `sesiones` (solo grupales)
- `sesiones` 1—1 `check_in`
- `sesiones` 1—N `notas_clinicas`
- `sesiones` 1—N `evaluaciones` (opcional)
- `pacientes` 1—N `planes_terapeuticos`
- `pacientes` 1—N `evaluaciones`
- `pacientes` 1—N `informes`
- `pacientes` 1—N `pagos`
- `pacientes` 1—N `solicitudes_portal`
- `instrumentos_tests` 1—N `evaluaciones`
- `instrumentos_tests` 1—N `plantillas_instrumento`

### N a N
- `pacientes` N—N `responsables` mediante `paciente_responsable`
- `grupos` N—N `pacientes` mediante `grupo_miembros`
- `roles` N—N `permisos` mediante `rol_permiso`
- `usuarios` N—N `roles` mediante `usuario_rol`

## 3) Índices sugeridos

### Agenda y sesiones
- `idx_sesiones_profesional_inicio` en `(profesional_id, fecha_inicio)`
- `idx_sesiones_paciente_inicio` en `(paciente_id, fecha_inicio)` WHERE `paciente_id is not null`
- `idx_sesiones_grupo_inicio` en `(grupo_id, fecha_inicio)` WHERE `grupo_id is not null`
- `idx_sesiones_estado_inicio` en `(estado_sesion, fecha_inicio)`
- `idx_checkin_estado` en `(estado_checkin)`

### Pacientes y trazabilidad clínica
- `idx_pacientes_rut` unique parcial en `(rut)` WHERE `rut is not null`
- `idx_planes_paciente_inicio` en `(paciente_id, fecha_inicio desc)`
- `idx_notas_sesion` en `(sesion_id)`
- `idx_notas_profesional_fecha` en `(profesional_id, created_at desc)`
- `idx_evaluaciones_paciente_fecha` en `(paciente_id, fecha_evaluacion desc)`
- `idx_informes_paciente_estado` en `(paciente_id, estado_informe)`

### Pagos y administración
- `idx_pagos_paciente_fecha` en `(paciente_id, fecha_pago desc)`
- `idx_pagos_sesion` en `(sesion_id)` WHERE `sesion_id is not null`
- `idx_pagos_tipo_fecha` en `(tipo_pago, fecha_pago)`
- `idx_solicitudes_estado_fecha` en `(estado_solicitud, created_at desc)`

### Seguridad y auditoría
- `idx_auditoria_entidad_fecha` en `(entidad_tipo, entidad_id, created_at desc)`
- `idx_auditoria_usuario_fecha` en `(usuario_id, created_at desc)`
- `idx_archivos_entidad` en `(entidad_tipo, entidad_id)`

### Sugerencias complementarias
- Índices parciales para excluir soft-deleted: `... WHERE deleted_at is null`.
- Restricción `exclude using gist` para evitar solapamiento de sesiones por profesional (`tsrange(fecha_inicio, fecha_fin)`).
- Trigger genérico para actualizar `updated_at` en cada `UPDATE`.
