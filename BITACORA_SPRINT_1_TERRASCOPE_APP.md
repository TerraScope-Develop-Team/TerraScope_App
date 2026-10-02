---
title: "BITÁCORA DE SPRINT 1 - TERRASCOPE APP"
subtitle: "Equipo de Desarrollo - Ciclo de Proyecto"
date: "2 de octubre de 2026"
---

# BITÁCORA DE SPRINT 1
## TERRASCOPE - Aplicación Móvil

---

## 📋 DATOS ADMINISTRATIVOS

| Aspecto | Descripción |
|--------|------------|
| **Equipo** | App (Mobile) |
| **Sprint #** | 1 |
| **Fecha de Cierre** | 2 de octubre de 2026 |
| **Redactor(a)** | Gonzalez Avalos, Cesar Fernando |
| **Facilitador(a)** | — |
| **Asistentes** | Chavez Piñon, Santiago Ronaldo; Torres Perez, Leonel Alejandro |
| **Ausentes y motivo** | — |

---

## 🎯 1. OBJETIVO DEL SPRINT

**Implementar funcionalidades de red social con sistema de feed personalizado, interacciones sociales (likes y comentarios), perfiles de usuario con gestión de seguimiento, y mejoras en alertas de fauna peligrosa con sincronización backend-frontend.**

---

## 📊 2. ESTADO DEL TABLERO

### Tabla de Issues

| Issue | Título | Responsable | Estado | Pts | Evidencia |
|-------|--------|-------------|--------|-----|-----------|
| #33 | Implementar sistema de red social y feed de usuarios seguidos | Chavez Piñon, S. R. | Hecho | 8 | PR #32 (Merged 02/10/2026) |
| #34 | Mejoras en alertas de fauna peligrosa y notificaciones | Gonzalez Avalos, C. F. | En revisión | 5 | PR #33 (Abierto) |
| #RNF-03 | Integración de Token JWT y migración Prisma Frontend | Gonzalez Avalos, C. F. | Hecho | 5 | PR #31 (Merged 30/09/2026) |
| N/A | Validación y estructuración de datos (Rnf03) | Torres Perez, L. A. | Hecho | 3 | PR #30 (Merged 25/09/2026) |

### Resumen de Progreso

| Categoría | Cantidad |
|-----------|----------|
| **Planeados** | 4 |
| **Terminados** | 3 |
| **En progreso** | 0 |
| **En revisión** | 1 |
| **Bloqueados** | 0 |

**Porcentaje de Completitud: 75%**

---

## 👥 3. STAND-UP POR INTEGRANTE

### Chavez Piñon, Santiago Ronaldo

| Pregunta | Respuesta |
|----------|-----------|
| **¿Qué hizo desde la última clase?** | Implementación completa del sistema de red social incluyendo: modelos de datos para perfiles sociales (UsuarioResumen, UsuarioPerfil), sistema de likes con contador en tiempo real, comentarios anidados con moderación, feed segmentado (Explorar todo / Siguiendo), vistas de perfil propio y ajeno con contadores de seguidores/seguidos, y flujo de seguimiento/dejar de seguir. |
| **¿Qué hará?** | Validación de feedback en testing, optimizaciones de performance en feed y resolución de issues menores reportados por equipo. |
| **¿Qué me bloquea?** | Ningún bloqueador identificado. |

### Gonzalez Avalos, Cesar Fernando

| Pregunta | Respuesta |
|----------|-----------|
| **¿Qué hizo desde la última clase?** | Implementación de Token JWT con migración completa de Prisma en frontend, resolución de conflictos en Gradle y configuración de autenticación. Actualmente en desarrollo de alertas de fauna peligrosa con banner de notificaciones en tiempo real y persistencia de estado de alertas. |
| **¿Qué hará?** | Finalizar PR #33 de alertas fauna peligrosa, testing completo del flujo de notificaciones y sincronización con backend. |
| **¿Qué me bloquea?** | Posibles conflictos de merge al integrar alertas con rama principal. Requiere coordinación para resolver. |

### Torres Perez, Leonel Alejandro

| Pregunta | Respuesta |
|----------|-----------|
| **¿Qué hizo desde la última clase?** | Implementación de validaciones contextuales de autenticación JWT, validación de esquema Prisma y estructuración de endpoints de seguridad. |
| **¿Qué hará?** | Apoyo en testing de features sociales, validaciones de comentarios y moderación de contenido. |
| **¿Qué me bloquea?** | Requiere coordinación con frontend para completar flujo de validación experta y comunitaria. |

---

## 🚀 4. SOFTWARE FUNCIONANDO

| Pregunta | Respuesta |
|----------|-----------|
| **¿Hay una versión ejecutable?** | ✅ Sí |
| **¿Cómo se prueba?** | Rama `main` con PRs mergeados (#32, #31, #30). Compilación en Android mediante `flutter run` con debugger USB. IP del backend configurable en `lib/config/api_config.dart`. |
| **Evidencia** | Múltiples PRs mergeados con cambios compilables y probados en dispositivo físico. |
| **Funcionalidades que ya se pueden demostrar** | • Feed personalizado (Explorar todo / Siguiendo)<br/>• Sistema de likes con actualización en tiempo real<br/>• Comentarios anidados en avistamientos<br/>• Perfiles de usuario con métricas<br/>• Seguimiento/Dejar de seguir usuarios<br/>• Autenticación con Token JWT<br/>• Votos de validación comunitaria y experta<br/>• Notificaciones de alertas de fauna peligrosa |

### Instrucciones para ejecutar

```bash
# 1. Sincronizar y limpiar Flutter
git pull origin main
flutter clean
flutter pub get

# 2. Configurar IP del backend en: lib/config/api_config.dart
# Ejemplo: static const String baseUrl = 'http://192.168.X.XXX:3000/api';

# 3. Ejecutar la aplicación
flutter run
```

---

## 📝 5. RETROALIMENTACIÓN RECIBIDA

*No se documentó retroalimentación externa durante este sprint.*

---

## 🔄 6. CAMBIOS Y DECISIONES

### Cambios Realizados

1. **Arquitectura de Modelos**: Se expandió significativamente el modelo `Avistamiento` para incluir soporte de likes, comentarios anidados y estado de validación. Se crearon nuevas estructuras `UsuarioResumen` y `UsuarioPerfil` para perfiles sociales.

2. **Configuración de Seguridad Android**: Se agregó `android:usesCleartextTraffic="true"` en `AndroidManifest.xml` para permitir conexiones HTTP en desarrollo local.

3. **Patrón de Autenticación**: Implementación de cliente HTTP personalizado que añade automáticamente el header `Authorization: Bearer <token>` a solicitudes del API de TerraScope, eliminando la necesidad de pasar credenciales en cada request.

4. **Resolución de Conflictos Gradle**: Unificación y limpieza de dependencias de versiones anteriores en `build.gradle` para resolver conflictos del merge anterior.

### Decisiones Tomadas

- **Segmentación del Feed**: Se decidió crear dos vistas de feed (Explorar todo / Siguiendo) para mejorar experiencia de usuario y permitir descubrimiento frente a contenido personalizado.
- **Migración JWT**: Prioritario completar migración de autenticación JWT antes de adicionar más features que requieran autenticación.
- **Validación en Tiempo Real**: Los votos comunitarios y expertos se procesan inmediatamente al enviar sin esperar recarga de página.

---

## ⚠️ 7. RIESGOS E IMPEDIMENTOS

| Riesgo o impedimento | Impacto | Acción y responsable |
|---------------------|--------|----------------------|
| Conflictos de merge en rama `main` por desarrollo paralelo | Medio | Coordinación diaria entre Ces4rGlez (alertas) y RonaldoChavez76 (social). Usar feature branches aisladas. **Responsable: Ces4rGlez** |
| Performance del feed con muchos likes/comentarios | Medio | Implementar paginación en comentarios y lazy loading de avatares. **Responsable: RonaldoChavez76** |
| PR #33 pendiente de revisión y merge | Alto | Priorizar revisión de PR de alertas para no bloquear integración. **Responsable: Ces4rGlez** |
| Diferencias entre IP local y producción en API config | Bajo | Documentar proceso de cambio de IP. Considerar archivo `.env` para configuración. **Responsable: Gonzalez Avalos, C. F.** |
| Certificado HTTPS no configurado para producción | Alto | Pendiente de investigación. Debe completarse antes de release. **Responsable: Torres Perez, L. A.** |

---

## 🔍 8. MINI RETROSPECTIVA

| Pregunta | Reflexión del equipo |
|----------|---------------------|
| **Qué funcionó bien** | • Comunicación clara en stand-ups<br/>• Entrega rápida de features complejas (3 PRs merged en corto tiempo)<br/>• Buena segregación de responsabilidades en el sistema de red social<br/>• Testing en dispositivo físico permitió detectar problemas temprano |
| **Qué debemos mejorar** | • Resolver PRs con mayor velocidad (PR #33 abierta desde 2 días atrás)<br/>• Mejor documentación en commit messages (algunos commits sin contexto claro)<br/>• Coordinar mejor para evitar conflictos de merge<br/>• Documentar cambios de configuración más claramente |
| **Un cambio concreto para la próxima clase** | Implementar SLA de máximo 24 horas para code reviews. Crear checklist de pre-merge que incluya: análisis estático, testing básico, documentación de cambios de configuración. |

---

## 📌 9. COMPROMISOS PARA LA PRÓXIMA CLASE

| Compromiso | Responsable | Issue # |
|------------|------------|---------|
| Mergear PR #33 (Alertas fauna peligrosa) y validar funcionamiento end-to-end | Gonzalez Avalos, C. F. | #34 |
| Ejecutar suite completa de tests en features sociales (likes, comentarios, seguimiento) | Chavez Piñon, S. R. | #33 |
| Documentar API endpoints de validación experta y comunitaria | Torres Perez, L. A. | #RNF-03 |
| Investigar y configurar certificado HTTPS para producción | Gonzalez Avalos, C. F. | — |
| Crear archivo `.env.example` con plantilla de configuración de IP | Chavez Piñon, S. R. | — |

---

## ⭐ 10. AUTOEVALUACIÓN DEL EQUIPO

| Métrica | Calificación (1-5) | Comentarios |
|---------|:--:|---------|
| **Comunicación** | ⭐⭐⭐⭐ (4) | Buena coordinación en stand-ups. Podría mejorar documentación de decisiones. |
| **Colaboración** | ⭐⭐⭐⭐ (4) | Trabajo colaborativo sólido. Algunos bloqueos por espera de merge de PRs. |
| **Calidad del código** | ⭐⭐⭐⭐ (4) | Código bien estructurado. Hay `TODO` y mejoras pendientes mencionadas en descripción de PR. |
| **Cumplimiento del plan** | ⭐⭐⭐⭐ (4) | 75% de objetivos completados. Una tarea (alertas) en revisión pero con progreso significativo. |

---

## 📌 NOTAS ADICIONALES

### Información Técnica Relevante

- **Tecnología Frontend**: Flutter (Dart) con Provider para state management
- **Autenticación**: Token JWT almacenado localmente y enviado en header `Authorization`
- **API Base**: Configurable en `lib/config/api_config.dart`
- **Validaciones**: Implementadas con validación comunitaria (votos) y experta (rol específico)
- **BD**: Prisma ORM en backend con modelos actualizados para soportar relaciones sociales

### Próximas Prioridades

1. ✅ Completar y mergear PR #33 (alertas fauna)
2. 📌 Investigar y resolver issue de certificado HTTPS
3. 📌 Mejorar documentación de endpoints en backend
4. 📌 Optimizar performance del feed con usuarios/avistamientos

---

**Documento generado el 2 de octubre de 2026**  
**Equipo: TerraScope Develop Team - Módulo App (Mobile)**