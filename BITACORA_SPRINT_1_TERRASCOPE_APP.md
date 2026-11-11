---
title: "BITÁCORA INTEGRAL DE DESARROLLO - TERRASCOPE (FRONTEND & BACKEND)"
subtitle: "Equipo de Desarrollo - Registro de Sprints, Commits y Pull Requests"
date: "5 de noviembre de 2026"
---

# BITÁCORA INTEGRAL DE DESARROLLO
## TERRASCOPE — Ecosistema Móvil (Flutter) y Backend API (Node.js / Express / Prisma)

---

## 📋 DATOS ADMINISTRATIVOS GENERALES

| Aspecto | Descripción |
|---|---|
| **Proyecto** | TerraScope (Monitoreo Ambiental, Gamificación, IA y Red Social Biológica) |
| **Repositorios** | `TerraScope_App` (Frontend Flutter) & `TerraScope-back` (Backend Express / Prisma) |
| **Periodo Registrado** | 25 de septiembre de 2026 – 5 de noviembre de 2026 |
| **Sprints Abarcados** | **Sprint 1** (Cierre formal), **Sprint 2** (Completado) y **Sprint 3** (Completado / Actual) |
| **Redactores / Integrantes** | • Chavez Piñon, Santiago Ronaldo<br/>• Gonzalez Avalos, Cesar Fernando<br/>• Torres Perez, Leonel Alejandro |
| **Estado General** | ✅ Software ejecutable, probado en físico y con suites de pruebas pasando |

---

# 🚀 SPRINT 1 (25 Septiembre – 4 Octubre 2026)
### MVP01 — Red Social, Autenticación JWT, Alertas de Fauna Peligrosa y Protocolo SOS

---

### 🎯 1. OBJETIVO DEL SPRINT 1
Implementar las funcionalidades fundacionales de la red social de biodiversidad (feed segmentado, likes, comentarios anidados y seguimiento entre usuarios), migrar la arquitectura de autenticación hacia tokens JWT con Prisma ORM en ambos repositorios, e integrar el motor de alertas geoespaciales de fauna peligrosa con protocolo de auxilio SOS y notificaciones en tiempo real vía WebSockets y Firebase Cloud Messaging (FCM).

---

### 📊 2. ESTADO DEL TABLERO — SPRINT 1

#### Tabla de Issues y Pull Requests (Frontend & Backend)

| Módulo | Issue / Ref | Título | Responsable | Estado | Pts | Evidencia |
|---|---|---|---|:---:|:---:|---|
| **App** | #33 | Sistema de red social y feed de seguidos | Chavez Piñon, S. R. | Hecho | 8 | PR #32 (Merged 01/10/2026) |
| **Back** | #33 | Endpoints de red social, likes, comentarios y seguidores | Chavez Piñon, S. R. | Hecho | 8 | PR #38 (Merged 25/09/2026) & PR #43 (Merged 30/09/2026) |
| **App** | #34 | Alertas de fauna peligrosa y botón SOS en UI | Gonzalez Avalos, C. F. | Hecho | 5 | PR #33 (Merged 04/10/2026) |
| **Back** | #34 | Motor de alertas geoespaciales y persistencia por usuario | Gonzalez Avalos, C. F. | Hecho | 5 | PR #47 (Merged 04/10/2026) |
| **App** | #RNF-03 | Integración de Token JWT y cliente autenticado | Gonzalez Avalos, C. F. | Hecho | 5 | PR #31 (Merged 29/09/2026) |
| **Back** | #RNF-03 | Migración a Prisma ORM, seed de hábitats y Swagger | Gonzalez Avalos, C. F. | Hecho | 5 | PR #40 (Merged 27/09/2026) |
| **App** | RNF03 | Validación de seguridad y estructuración de modelos | Torres Perez, L. A. | Hecho | 3 | PR #30 (Merged 25/09/2026) |
| **Back** | RNF03 | Implementación de protocolos de seguridad | Torres Perez, L. A. | Hecho | 3 | PR #36 / #37 (Merged 25/09/2026) |
| **App** | MVP03 | Manejo de FCM e inicialización de sesiones guardadas | Equipo TerraScope | Hecho | 5 | PR #34 (Merged 04/10/2026) |
| **Back** | MVP03 | Despacho de eventos push FCM y registro de retos | Equipo TerraScope | Hecho | 5 | PR #51 (Merged 04/10/2026) |

#### Resumen de Progreso — Sprint 1

| Categoría | Cantidad |
|---|:---:|
| **Tareas Planeadas** | 10 |
| **Tareas Terminadas** | 10 |
| **En Progreso / Bloqueadas** | 0 |
| **Porcentaje de Cumplimiento** | **100%** |

---

### 👥 3. STAND-UP POR INTEGRANTE — SPRINT 1

#### Chavez Piñon, Santiago Ronaldo
* **¿Qué hizo?**: Desarrollo integral del subsistema de red social: backend con endpoints de interacción social (`POST /usuarios/:id/seguir`, `POST /fauna-flora/:id/like`, `POST /fauna-flora/:id/comentarios`), soporte en esquema Prisma, y en frontend los modelos (`UsuarioResumen`, `UsuarioPerfil`), feed segmentado (Explorar / Siguiendo), contadores de likes en tiempo real y vista de perfiles.
* **¿Qué hará para el siguiente ciclo?**: Optimización en el envío de imágenes a IA (RT03), sistema de caché de consultas y métricas de rendimiento en API (RNF02).
* **¿Qué le bloquea?**: Ningún bloqueador en el cierre del sprint.

#### Gonzalez Avalos, Cesar Fernando
* **¿Qué hizo?**: Migración de backend a Prisma ORM con MongoDB, integración de Token JWT y middleware `verificarToken`. En frontend, resolución de conflictos de Gradle, implementación de banner de alertas de fauna peligrosa en tiempo real, persistencia de estado de alertas por usuario y botón SOS.
* **¿Qué hará para el siguiente ciclo?**: Refactorización de servicios HTTP en frontend (RT01) y enriquecimiento de las notificaciones geoespaciales.
* **¿Qué le bloquea?**: Dependencias cruzadas de red y variaciones de IP en desarrollo local.

#### Torres Perez, Leonel Alejandro
* **¿Qué hizo?**: Validación contextual de autenticación JWT en frontend y backend, revisión de esquemas de seguridad en headers HTTP, revisión y merge de Pull Requests centrales a `develop` y `main`.
* **¿Qué hará para el siguiente ciclo?**: Coordinar la revisión de código de las capas de servicio y soporte en pruebas de integración.
* **¿Qué le bloquea?**: Coordinación de horarios para resolver ramas de testing simultáneas.

---

### 🚀 4. SOFTWARE FUNCIONANDO — SPRINT 1
* **Versión Ejecutable**: Sí (`TerraScope_App` en Android y `TerraScope-back` en Node.js v20+).
* **Funcionalidades Demostrables**:
  1. Autenticación con Token JWT y almacenamiento seguro de credenciales.
  2. Feed de exploración general y feed filtrado para usuarios que se siguen.
  3. Sistema de likes instantáneos y comentarios anidados en avistamientos.
  4. Perfiles públicos y propios con métricas de seguidores y seguidos.
  5. Banner interactivo de alerta ante detección de fauna peligrosa cercana.
  6. Envío de alerta de auxilio geolocalizada mediante botón SOS.

---

### 🔄 5. CAMBIOS Y DECISIONES — SPRINT 1
1. **Unificación en Prisma ORM**: Se reemplazó el acceso directo por Mongoose/Nativo por Prisma Client, asegurando tipado estricto en MongoDB.
2. **Cliente HTTP Centralizado**: El frontend encapsula el header `Authorization: Bearer <token>` para evitar inyecciones manuales en cada petición.
3. **Persistencia de Alertas**: Se agregó el modelo `AlertaPeligro` en MongoDB para que las notificaciones no se pierdan si el usuario está offline.

---

# ⚡ SPRINT 2 (5 Octubre – 15 Octubre 2026)
### MVP03 — Rendimiento, Caché y Optimización de IA (RT03), Capa de Servicios Backend (RT02) y Refactor Frontend (RT01)

---

### 🎯 1. OBJETIVO DEL SPRINT 2
Optimizar drásticamente la latencia y los costos de consumo de la API de Google Gemini implementando compresión y redimensionamiento de imágenes junto con un caché en memoria (RT03), reestructurar la arquitectura del backend desacoplando controladores hacia una capa de servicios (`src/services/`) con resiliencia ante fallos (RT02), centralizar la capa HTTP del frontend (RT01) e integrar plenamente las notificaciones push vía Firebase Admin SDK.

---

### 📊 2. ESTADO DEL TABLERO — SPRINT 2

#### Tabla de Issues y Pull Requests (Frontend & Backend)

| Módulo | Issue / Ref | Título | Responsable | Estado | Pts | Evidencia |
|---|---|---|---|:---:|:---:|---|
| **Back** | #24 / RT03 | Optimización de imágenes (Sharp) y caché SHA-256 para Gemini | Chavez Piñon, S. R. | Hecho | 8 | PR #48 (Merged 04/10/2026) |
| **Back** | RNF02 | Optimización de consultas y limitación de llamadas a IA | Chavez Piñon, S. R. | Hecho | 5 | PR #49 (Merged 04/10/2026) |
| **App** | RNF02 | Timeout de IA y búsqueda remota en frontend | Chavez Piñon, S. R. | Hecho | 5 | PR #35 (Merged 13/10/2026) |
| **Back** | RT02 | Refactorización: desacoplamiento a capa de servicios y resiliencia Gemini | Chavez Piñon, S. R. | Hecho | 8 | PR #52 (Merged 14/10/2026) |
| **App** | #22 / RT01 | Refactor centralizado de servicios HTTP, `api_client` unificado | Gonzalez Avalos, C. F. | Hecho | 8 | PR #37 (Merged 15/10/2026) |
| **Back** | #34 | Enriquecimiento de alertas de fauna con nombre común y especie | Gonzalez Avalos, C. F. | Hecho | 3 | PR #53 (Merged 15/10/2026) |
| **App** | MVP03 | Corrección en validaciones de avistamiento (`avistamiento_validation`) | Equipo TerraScope | Hecho | 3 | PR #38 (Merged 15/10/2026) |
| **Back/App**| CI/CD | Integración de ramas a `main` y sincronización develop | Torres Perez, L. A. | Hecho | 3 | PR #36 Front / PR #46 Back |

#### Resumen de Progreso — Sprint 2

| Categoría | Cantidad |
|---|:---:|
| **Tareas Planeadas** | 8 |
| **Tareas Terminadas** | 8 |
| **En Progreso / Bloqueadas** | 0 |
| **Porcentaje de Cumplimiento** | **100%** |

---

### 👥 3. STAND-UP POR INTEGRANTE — SPRINT 2

#### Chavez Piñon, Santiago Ronaldo
* **¿Qué hizo?**: 
  - **RT03 (IA Cache & Compresión)**: Creación de `ia-cache.service.js` con hash SHA-256 sobre imágenes base64, TTL de 24 horas, métricas de hit/miss (`GET /api/ia/stats`), purga horaria en `server.js` e integración con `sharp` para optimización y resize automático previo al envío a Gemini.
  - **RT02 (Capa de Servicios)**: Extracción de lógica de negocio de los controladores a `src/services/` (`fauna_flora.service.js`, `usuario.service.js`, `retos.service.js`), implementación de reintentos y fallback automático de modelos ante errores 503 de Gemini, y resolución de conectividad con réplicas de MongoDB local.
  - **RNF02**: Medición de latencia de endpoints (`measure-api-latency.js`) y timeout controlado de peticiones de IA en Flutter.
* **¿Qué hará para el siguiente ciclo?**: Implementar el sistema de recomendaciones geoespaciales de avistamientos cercanos (Issue #45) tanto en backend como en frontend.
* **¿Qué le bloquea?**: Ninguno.

#### Gonzalez Avalos, Cesar Fernando
* **¿Qué hizo?**:
  - **RT01 (Refactor Frontend)**: Centralización de todas las peticiones REST en `ApiClient` con manejo uniforme de excepciones (`ApiException`), unificación de endpoints y sanitización de caracteres/emojis en la UI.
  - Mejora en la notificación de fauna peligrosa incluyendo el nombre taxonómico y científico en el payload enviado al dispositivo.
* **¿Qué hará para el siguiente ciclo?**: Apoyo en pruebas de integración de avistamientos cercanos y validaciones de interfaz.
* **¿Qué le bloquea?**: Ajustes de renderizado en modelos de mapa.

#### Torres Perez, Leonel Alejandro
* **¿Qué hizo?**: Pruebas de regresión sobre las rutas refactorizadas, validación de esquemas Swagger y orquestación de Pull Requests para estabilizar la rama `main`.
* **¿Qué hará para el siguiente ciclo?**: Coordinar la revisión de código del sistema de votaciones comunitarias (MVP04).
* **¿Qué le bloquea?**: Ninguno.

---

### 🚀 4. SOFTWARE FUNCIONANDO — SPRINT 2
* **Versión Ejecutable**: Sí.
* **Funcionalidades Demostrables**:
  1. Identificación con Gemini con respuesta instantánea (~5 ms) en caso de caché HIT.
  2. Reducción comprobada de más del 60% en el peso de imágenes enviadas al backend gracias a `sharp`.
  3. Resiliencia ante indisponibilidad de Gemini con conmutación por fallback.
  4. Capa HTTP unificada en Flutter con captura global de errores de red y tokens expirados.
  5. Despacho y recepción de notificaciones Push mediante Firebase Admin SDK.

---

### 🔄 5. CAMBIOS Y DECISIONES — SPRINT 2
1. **Desacoplamiento Estricto Controller-Service**: Ningún controlador Express debe interactuar directamente con Prisma; toda regla de negocio reside en `src/services/`.
2. **Caché en Memoria con Purga Asíncrona**: Para evitar sobrecostos en Gemini sin requerir infraestructura externa adicional (como Redis), se implementó un `Map` en memoria con clave SHA-256 y ciclo de purga cada 60 minutos en segundo plano.

---

# 🌐 SPRINT 3 (16 Octubre – 23 Octubre / 5 Noviembre 2026)
### MVP04 — Geolocalización Haversine (#45), Validación Democrática con Ventana Temporal y Rate Limiting (RT06 #27)

---

### 🎯 1. OBJETIVO DEL SPRINT 3
Implementar el sistema de recomendaciones inteligentes de avistamientos por proximidad geográfica basado en la fórmula del semiverseno (Haversine) y su visualización en Flutter (Issue #45), desplegar el motor de validación comunitaria democrática en tiempo real con ventana de votación temporal y worker en segundo plano (MVP04), e implementar rate limiting en memoria en los endpoints más sensibles (Login e IA) para mitigar ataques de fuerza bruta y abusos de API (RT06 / Issue #27).

---

### 📊 2. ESTADO DEL TABLERO — SPRINT 3

#### Tabla de Issues y Pull Requests (Frontend & Backend)

| Módulo | Issue / Ref | Título | Responsable | Estado | Pts | Evidencia |
|---|---|---|---|:---:|:---:|---|
| **Back** | #45 | Endpoint de recomendaciones de avistamientos cercanos (`/recomendados`) | Chavez Piñon, S. R. | Hecho | 8 | PR #54 (Merged 22/10/2026) |
| **App** | #45 | Integración en UI Flutter de avistamientos cercanos por distancia | Chavez Piñon, S. R. | Hecho | 8 | PR #39 (Merged 22/10/2026) |
| **Back** | MVP04 | Validación comunitaria democrática con ventana temporal y worker | Equipo TerraScope | Hecho | 13 | PR #56 (Merged 23/10/2026) |
| **Back** | #27 / RT06 | Rate Limiting en endpoints sensibles (`/login` e `/ia/identificar`) | Chavez Piñon, S. R. | Hecho | 8 | Rama `feat/rt06-rate-limiting` (Commit `1516df1`) |
| **Back/App**| CI/CD | Merge de sincronización de releases a `main` | Torres Perez, L. A. | Hecho | 3 | PR #40 Front / PR #55 Back |
| **Back** | Docs | Documentación integral de arquitectura y README del backend | Equipo TerraScope | Hecho | 5 | Commit `d1e4d42` / `1767099` |

#### Resumen de Progreso — Sprint 3

| Categoría | Cantidad |
|---|:---:|
| **Tareas Planeadas** | 6 |
| **Tareas Terminadas** | 6 |
| **En Progreso / Bloqueadas** | 0 |
| **Porcentaje de Cumplimiento** | **100%** |

---

### 👥 3. STAND-UP POR INTEGRANTE — SPRINT 3

#### Chavez Piñon, Santiago Ronaldo
* **¿Qué hizo?**:
  - **Issue #45 (Avistamientos Cercanos)**: 
    - *Backend*: Implementación de la función `selectAvistamientoRecommendations` con cálculo esférico Haversine, filtro por radio configurable (1 km por defecto), ordenamiento ascendente por distancia en metros, exclusión del espécimen consultado y fallback automático a los 5 avistamientos más recientes de la misma especie cuando no hay registros geográficos en el radio.
    - *Frontend*: Creación de los modelos `AvistamientoRecomendado` y `RecomendacionesResponse`, integración en `AvistamientoDetailPage` con tarjeta de distancia en vivo y fallback visual cuando no hay coordenadas disponibles.
  - **RT06 (Rate Limiting en Endpoints Sensibles #27)**:
    - Creación de `src/services/rate-limiter.service.js` con control de ventanas temporales en memoria, purga periódica para evitar fugas de memoria y soporte de cabeceras HTTP estándar (`Retry-After`, `X-RateLimit-*`).
    - Creación de `src/middlewares/rate-limit.middleware.js`:
      - `loginRateLimiter`: 5 intentos por cada 15 minutos por combinación `IP:email` para bloquear ataques de fuerza bruta.
      - `iaRateLimiter`: 10 peticiones por minuto por usuario autenticado (`req.usuario.id`) para evitar abuso y costos de Gemini.
    - Tarea programada en `server.js` de purga cada 10 minutos.
    - Suite de 12 pruebas automatizadas (`test/rate-limiter.service.test.js` y `test/rate-limit.middleware.test.js`) 100% superadas.
* **¿Qué hará?**: Monitoreo de estabilidad de endpoints, verificación de métricas y preparación para la entrega final del proyecto.
* **¿Qué le bloquea?**: Ninguno.

#### Gonzalez Avalos, Cesar Fernando
* **¿Qué hizo?**: Pruebas de integración entre la UI de Flutter y los endpoints de votación en tiempo real de fauna y flora, verificación de compatibilidad de tipos geográficos entre Dart y MongoDB, y pruebas de estrés de los límites de login.
* **¿Qué hará?**: Pruebas de usuario final en diferentes dispositivos Android.
* **¿Qué le bloquea?**: Ninguno.

#### Torres Perez, Leonel Alejandro
* **¿Qué hizo?**: Revisión de Pull Requests centrales (#39, #40, #54, #55, #56), verificación de documentación Swagger en `/api/docs`, y validación de las respuestas 429 (`Too Many Requests`) con cabeceras `Retry-After`.
* **¿Qué hará?**: Auditoría final de seguridad y empaquetado de entregables.
* **¿Qué le bloquea?**: Ninguno.

---

### 🚀 4. SOFTWARE FUNCIONANDO — SPRINT 3
* **Versión Ejecutable**: Sí (ambos repositorios completamente alineados y operativos).
* **Funcionalidades Demostrables**:
  1. **Recomendaciones Geoespaciales**: Al abrir el detalle de cualquier avistamiento, la app consulta el backend y muestra los hallazgos biológicos situados en un radio de 1 km ordenados por cercanía. Si no existen especímenes cercanos, despliega recomendaciones de la misma especie.
  2. **Validación Democrática MVP04**: 
     - Sistema de votos a favor y en contra con recuento en tiempo real.
     - Ventana temporal de 24 horas que premia el consenso sobre la velocidad.
     - Eliminación automática inmediata si alcanza mayoría negativa.
     - Worker en segundo plano en `server.js` que revisa votaciones vencidas cada 60 segundos y elimina avistamientos abandonados o con mayoría negativa.
  3. **Seguridad y Rate Limiting (RT06)**:
     - Bloqueo en el 6º intento de login fallido con respuesta HTTP 429 y header `Retry-After` con cuenta regresiva.
     - Límite de 10 llamadas por minuto por usuario para identificar especies con Gemini.
     - Purga automática en memoria cada 10 minutos.

---

### 🔄 5. CAMBIOS Y DECISIONES — SPRINT 3
1. **Algoritmo Haversine en Memoria vs. Índices $nearSphere**: Se optó por calcular distancias con la fórmula matemática del semiverseno en `fauna_flora.service.js` para asegurar compatibilidad transparente tanto con bases locales independientes de réplicas como con clústeres Atlas sin forzar índices 2dsphere complejos en Prisma.
2. **Rate Limiter en Memoria sin Dependencias Externas**: Se implementó una solución nativa basada en `Map` con purga periódica, garantizando cero dependencias externas (sin Redis ni paquetes vulnerables de terceros), asegurando máxima portabilidad y velocidad sub-milisegundo.
3. **Respuesta 429 Estándar RFC 6585**: Toda petición bloqueada incluye obligatoriamente el header `Retry-After: <segundos>` para que la aplicación móvil informe al usuario exactamente cuándo podrá reintentar.

---

### ⚠️ 6. MATRIZ DE RIESGOS E IMPEDIMENTOS CONSOLIDADA

| Riesgo / Impedimento | Impacto | Estado | Mitigación Implementada | Responsable |
|---|:---:|:---:|---|---|
| Ataques de fuerza bruta en inicio de sesión | Alto | **Mitigado** | Rate limiting de 5 intentos por 15 min con respuesta 429 y `Retry-After`. | Chavez Piñon, S. R. |
| Costos elevados y cuotas excedidas en Google Gemini | Alto | **Mitigado** | Compresión de imágenes (`sharp`), caché SHA-256 (24h) y rate limiting de 10 req/min. | Chavez Piñon, S. R. |
| Caídas 503 en la API de Google Gemini | Medio | **Mitigado** | Reintentos exponenciales y fallback automático de modelos en `gemini-request.service.js`. | Chavez Piñon, S. R. |
| Avistamientos fraudulentos o erróneos en el mapa | Alto | **Mitigado** | Ventana temporal de votación comunitaria y eliminación automática por worker. | Equipo TerraScope |
| Fugas de memoria por acumulación de claves en caché / rate limit | Medio | **Mitigado** | Schedulers periódicos en `server.js` para purga automática de entradas expiradas. | Chavez Piñon, S. R. |
| Conectividad móvil bloqueada en redes Wi-Fi institucionales | Medio | **Mitigado** | Configuración de puente USB mediante `adb reverse tcp:3000 tcp:3000` y `127.0.0.1`. | Chavez Piñon, S. R. |

---

### 🔍 7. RETROSPECTIVA GENERAL DEL EQUIPO

| Aspecto | Reflexión del Equipo |
|---|---|
| **Qué funcionó bien** | • Excelente sinergia entre frontend y backend: los requerimientos se completaron en espejo con sus respectivos Pull Requests.<br/>• La suite de pruebas unitarias con el runner nativo (`node:test`) permitió iterar rápidamente sin overhead de configuración.<br/>• Alta calidad arquitectónica gracias al desacoplamiento en capas de servicios y middlewares reutilizables.<br/>• Resoluciones rápidas de conflictos de ramas mediante git rebase/merge estructurado. |
| **Qué se mejoró respecto al Sprint 1** | • Se redujo drásticamente el tiempo de revisión de Pull Requests (de 2 días a pocas horas).<br/>• Los commits ahora siguen la convención de *Conventional Commits* en español con detalle de cambios.<br/>• Documentación exhaustiva en Swagger y README general del proyecto. |
| **Lecciones Aprendidas** | • Los límites de peticiones y cachés deben considerarse desde el diseño inicial de las features de IA para evitar sorpresas de facturación y cuotas.<br/>• Probar tempranamente en dispositivos físicos bajo diferentes escenarios de red previene problemas de configuración IP en producción. |

---

### ⭐ 8. AUTOEVALUACIÓN DEL EQUIPO (ESCALA 1-5)

| Métrica | Sprint 1 | Sprint 2 | Sprint 3 | Comentarios |
|---|:---:|:---:|:---:|---|
| **Comunicación** | ⭐⭐⭐⭐ (4.0) | ⭐⭐⭐⭐⭐ (5.0) | ⭐⭐⭐⭐⭐ (5.0) | Excelente flujo de acuerdos en stand-ups y trazabilidad en GitHub. |
| **Colaboración** | ⭐⭐⭐⭐ (4.0) | ⭐⭐⭐⭐⭐ (5.0) | ⭐⭐⭐⭐⭐ (5.0) | Apoyo mutuo en debugging y resolución ágil de bloqueos. |
| **Calidad del Código** | ⭐⭐⭐⭐ (4.0) | ⭐⭐⭐⭐⭐ (5.0) | ⭐⭐⭐⭐⭐ (5.0) | Código modular, desacoplado, sin emojis informales y con pruebas unitarias. |
| **Cumplimiento del Plan** | ⭐⭐⭐⭐ (4.0) | ⭐⭐⭐⭐⭐ (5.0) | ⭐⭐⭐⭐⭐ (5.0) | 100% de las tareas de los tres sprints concluidas y mergeadas. |

---

# 📑 REGISTRO MAESTRO DE TRAZABILIDAD
## Historial Completo de Pull Requests y Commits (Frontend & Backend)

### 📱 Repositorio Frontend: `TerraScope_App`

| Hash | Fecha | Autor | PR / Rama | Descripción del Cambio e Impacto |
|---|:---:|---|---|---|
| `b5ff8fb` | 2026-10-22 | L. A. Torres Pérez | PR #40 | Merge develop into main: integración general de recomendaciones cercanas |
| `55cb3f3` | 2026-10-22 | L. A. Torres Pérez | PR #39 | Merge feat/issue-45-avistamientos-cercanos into develop |
| `29c4dca` | 2026-10-20 | S. R. Chavez Piñon | `feat/issue-45` | feat(fauna-flora): integrar recomendaciones de avistamientos cercanos en la UI (issue #45) |
| `3f0c8f1` | 2026-10-15 | L. A. Torres Pérez | PR #38 | Merge pull request #38 MVP03: corrección de validaciones de avistamientos |
| `90dd2ae` | 2026-10-15 | AplicacionAndroidCRUD | MVP03 | fix:/Correccion en avistamiento_validation |
| `76079cd` | 2026-10-15 | L. A. Torres Pérez | PR #37 | Merge pull request #37: refactorización de servicios frontend (RT01) |
| `03477d0` | 2026-10-15 | C. F. Gonzalez Avalos | `fix/reestructuracion` | feat(services): refactor centralizado de servicios HTTP - RT01 #22 |
| `56dee64` | 2026-10-15 | C. F. Gonzalez Avalos | `fix/reestructuracion` | fix(services): resolver cierre y delegación en searchAvistamientos |
| `50af842` | 2026-10-15 | C. F. Gonzalez Avalos | `fix/reestructuracion` | feat(services): refactor servicios frontend, api_client unificado y limpieza de emojis (RT01) |
| `a2d45c8` | 2026-10-13 | L. A. Torres Pérez | PR #36 | Merge develop into main: estabilización de release intermedia |
| `38f79cf` | 2026-10-13 | L. A. Torres Pérez | PR #35 | Merge pull request #35: rendimiento de API y timeout en frontend (RNF02) |
| `dc8f623` | 2026-10-06 | S. R. Chavez Piñon | `feat/rnf02` | Merge origin/develop into feat/rnf02-rendimiento-api |
| `5cb7657` | 2026-10-04 | L. A. Torres Pérez | PR #34 | Merge pull request #34 MVP03: gestión de notificaciones FCM y sesión |
| `b172939` | 2026-10-04 | L. A. Torres Pérez | PR #33 | Merge pull request #33: alertas de fauna peligrosa y botón SOS |
| `e1ebe5a` | 2026-10-04 | AplicacionAndroidCRUD | MVP03 | feat(notifications): add FCM handling and restore saved sessions |
| `ed954c2` | 2026-10-03 | S. R. Chavez Piñon | `feat/rnf02` | Agrega timeout de IA y búsqueda remota en cliente |
| `698ee52` | 2026-10-02 | C. F. Gonzalez Avalos | `main` | docs: Crear bitácora oficial Sprint 1 - Sistema de red social y alertas |
| `6927f83` | 2026-10-02 | C. F. Gonzalez Avalos | `feat/alertas` | feat(notificaciones): mostrar alerta pendiente en banner interactivo |
| `62acc8f` | 2026-10-02 | C. F. Gonzalez Avalos | `feat/alertas` | feat: progreso en alertas de fauna peligrosa y botón SOS |
| `9bf249a` | 2026-10-01 | L. A. Torres Pérez | PR #32 | Merge pull request #32: sistema de red social y feed de seguidos (#33) |
| `3e0e0d3` | 2026-09-30 | S. R. Chavez Piñon | `feat/issue-33` | feat(social): permitir tráfico local, votación y retroalimentación de seguimiento (#33) |
| `4da5ebe` | 2026-09-29 | S. R. Chavez Piñon | `feat/issue-33` | feat(social): implementar likes, comentarios, feed de seguidos y perfiles (#33) |
| `0f9ddda` | 2026-09-29 | L. A. Torres Pérez | PR #31 | Merge pull request #31: integración de JWT y autenticación |
| `a50ef29` | 2026-09-26 | C. F. Gonzalez Avalos | `feat/token-jwt` | feat: JWT auth integration and merge conflict resolution |
| `858ddbc` | 2026-09-25 | L. A. Torres Pérez | PR #30 | Merge pull request #30: cambios de seguridad en la aplicación (RNF03) |
| `443b428` | 2026-09-25 | AplicacionAndroidCRUD | RNF03 | fix:/ Cambios en la seguridad de la aplicación |

---

### 🖥 Repositorio Backend: `TerraScope-back`

| Hash | Fecha | Autor | PR / Rama | Descripción del Cambio e Impacto |
|---|:---:|---|---|---|
| `1516df1` | 2026-10-23 | S. R. Chavez Piñon | `feat/rt06` | feat(seguridad): implementar rate limiting en endpoints de login e IA (#27) con cabeceras Retry-After y 12 tests |
| `1767099` | 2026-10-23 | L. A. Torres Pérez | PR #56 | Merge pull request #56 MVP04: validación comunitaria democrática en tiempo real y README |
| `d1e4d42` | 2026-10-23 | AplicacionAndroidCRUD | MVP04 | feat(voting): implementar sistema de votacion comunitaria MVP04 y documentación README |
| `a1495d1` | 2026-10-22 | L. A. Torres Pérez | PR #55 | Merge develop into main: release sincronizada con Frontend |
| `93a95a1` | 2026-10-22 | L. A. Torres Pérez | PR #54 | Merge pull request #54: recomendaciones de avistamientos cercanos (Issue #45) |
| `6b5a666` | 2026-10-20 | S. R. Chavez Piñon | `feat/issue-45` | feat(fauna-flora): endpoint de avistamientos cercanos por ubicación con Haversine y fallback de especie (#45) |
| `b67f65c` | 2026-10-15 | L. A. Torres Pérez | PR #53 | Merge pull request #53: enriquecimiento de alertas de fauna peligrosa |
| `a30ec73` | 2026-10-15 | C. F. Gonzalez Avalos | `feat/alertas` | feat(alertas): enriquecer alertas de fauna peligrosa con nombre de especie |
| `64f0eb5` | 2026-10-14 | L. A. Torres Pérez | PR #52 | Merge pull request #52: desacoplamiento arquitectónico en capa de servicios (RT02) |
| `07fb8d8` | 2026-10-14 | S. R. Chavez Piñon | `feat/rt02` | fix: limitar retos y mejorar resiliencia de Gemini con fallback |
| `2dba33a` | 2026-10-14 | S. R. Chavez Piñon | `feat/rt02` | fix: evitar conflicto con MongoDB local |
| `7c8e24e` | 2026-10-13 | S. R. Chavez Piñon | `feat/rt02` | refactor: mover la lógica de controladores a la capa de servicios desacoplada |
| `ab33a1d` | 2026-10-04 | L. A. Torres Pérez | PR #46 | Merge develop into main: release Sprint 1 |
| `a5fd12f` | 2026-10-04 | L. A. Torres Pérez | PR #47 | Merge pull request #47: alertas de fauna peligrosa y estado de notificaciones |
| `aef0d57` | 2026-10-04 | L. A. Torres Pérez | PR #48 | Merge pull request #48: optimización de imágenes y caché IA (RT03 / #24) |
| `223b4d9` | 2026-10-04 | L. A. Torres Pérez | PR #49 | Merge pull request #49: rendimiento API y optimización de consultas (RNF02) |
| `a671230` | 2026-10-04 | L. A. Torres Pérez | PR #51 | Merge pull request #51 MVP03: notificaciones FCM y retos |
| `e93b89d` | 2026-10-04 | AplicacionAndroidCRUD | MVP03 | feat(notifications): integrate FCM events and challenge enrollment |
| `a36fdb6` | 2026-10-03 | S. R. Chavez Piñon | `feat/rnf02` | Optimiza consultas y limita llamadas a Gemini |
| `082c0c1` | 2026-10-02 | S. R. Chavez Piñon | `feat/rt03` | Corrige seguimiento social y optimización de imágenes con IA |
| `8c9916a` | 2026-10-01 | S. R. Chavez Piñon | `feat/rt03` | feat(ia): optimización de imágenes y caché SHA-256 para identificación de especies |
| `6df8d3e` | 2026-10-02 | C. F. Gonzalez Avalos | `feat/alertas` | feat(alertas): guardar el estado de notificaciones por usuario |
| `11b6b55` | 2026-09-30 | L. A. Torres Pérez | PR #43 | Merge pull request #43: compatibilidad de auth y validaciones sociales (#33) |
| `85aded1` | 2026-09-30 | S. R. Chavez Piñon | `feat/issue-33` | feat(social): corregir compatibilidad de middleware de auth y validación de avistamientos (#33) |
| `80cbb20` | 2026-09-27 | L. A. Torres Pérez | PR #40 | Merge pull request #40: migración a Prisma ORM, JWT, seed y Swagger |
| `c4d1e58` | 2026-09-26 | C. F. Gonzalez Avalos | `feat/token-jwt` | chore: untrack node_modules from git |
| `4ce3de6` | 2026-09-26 | C. F. Gonzalez Avalos | `feat/token-jwt` | feat: integrate social features (likes, followers, comments) into Prisma schema and controllers |
| `55d4739` | 2026-09-25 | L. A. Torres Pérez | PR #38 | Merge pull request #38: sistema de likes, comentarios y seguidores (#33) |
| `7846973` | 2026-09-25 | S. R. Chavez Piñon | `feature/issue-33` | feat: agregar sistema de likes, comentarios y seguidores para MVP01 (#33) |
| `4ccc7dc` | 2026-09-25 | L. A. Torres Pérez | PR #37 | Merge pull request #37: protocolos de seguridad y validaciones (RNF03) |
| `9fc4e08` | 2026-09-25 | L. A. Torres Pérez | PR #36 | Merge pull request #36: implementación de protocolos de seguridad |

---

## 📌 GUÍA DE VERIFICACIÓN Y PRUEBAS EN PRODUCCIÓN/DESARROLLO

### 1. Ejecución del Backend
```bash
cd c:\Proyectos\Terrascope\TerraScope-back\terrascope-back
npm install
npm test
npm run dev
```

### 2. Ejecución de la Suite de Rate Limiting y Servicios
```bash
node --test --test-force-exit test/rate-limiter.service.test.js test/rate-limit.middleware.test.js
```

### 3. Ejecución de la App Móvil Flutter (con puente USB)
```bash
# Habilitar forwarding local de puertos para evitar aislamiento Wi-Fi:
adb reverse tcp:3000 tcp:3000

cd c:\Proyectos\Terrascope\TerraScope_App\terrascope
flutter clean
flutter pub get
flutter run
```

---

**Documento actualizado y certificado al 5 de noviembre de 2026**  
**Equipo TerraScope Development Team**  
*Módulo Mobile (Flutter) & Módulo Backend Core (Node.js / Express / Prisma)*
