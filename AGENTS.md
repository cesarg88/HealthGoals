# Instrucciones para agentes

Estas instrucciones se aplican a todo el repositorio.

## Antes de trabajar

- Lee [README.md](README.md), el [workflow manual](agents/README.md), la Issue asignada y sus referencias.
- Inspecciona el estado de Git y los archivos afectados. Conserva cambios ajenos.
- Usa exclusivamente `Cesar-IA-Agent` (`cesar-ia-agent[bot]`) para acceso autenticado a GitHub y autoría de commits. Lee y cumple [la política de autenticación](agents/github-authentication.md); nunca recurras a cuentas personales, de trabajo o SSH como alternativa.
- Usa una Issue como unidad de ejecución. Debe contener contexto suficiente sin depender del historial de un chat: objetivo, alcance, exclusiones, referencias, dependencias y criterios de aceptación verificables.
- Si falta una decisión necesaria, registra el bloqueo y solicita a César o al responsable de la Issue que lo resuelva. No inventes requisitos de producto ni criterios para poder cerrar la tarea.
- Usa una rama y un checkout/worktree exclusivos por agente y tarea. No compartas un directorio de trabajo con otro agente activo ni trabajes directamente sobre la rama de integración. César indica la base; actualmente es `develop`.

## Kit reutilizable

- Usa los roles [coordinator](agents/roles/coordinator.md), [implementer](agents/roles/implementer.md) y [reviewer](agents/roles/reviewer.md) según tu ejecución, y las skills locales `implement-issue` y `review-pr` en `.agents/skills/`.
- La política de este repositorio prevalece sobre los ejemplos genéricos del kit: aquí solo está autorizado el modo App.
- Las copias están fijadas en [kit-lock.json](agents/kit-lock.json). Las mejoras reutilizables se integran primero en el kit; su adopción aquí requiere una Issue, un nuevo SHA integrado, copias exactas y hashes actualizados. No edites las copias como una implementación local independiente.

## Durante la ejecución

- Limita los cambios a la Issue; mantén las PRs pequeñas y revisables.
- Actualiza la documentación afectada junto con el cambio. Guarda las decisiones duraderas en `docs/decisions/` cuando corresponda.
- No añadas frameworks, dependencias, automatizaciones ni abstracciones para necesidades hipotéticas.
- No implementes features ni crees el proyecto Xcode como consecuencia implícita de preparar documentación o infraestructura.
- No incluyas credenciales ni datos personales de salud en commits, fixtures, Issues o PRs.

## Entrega y revisión

- Explica qué cambió y vincula cada criterio de aceptación con evidencia o un procedimiento reproducible de validación.
- Ejecuta los checks disponibles y los apropiados al cambio. Distingue checks ejecutados, pendientes y no aplicables; no afirmes haber compilado o probado una app que aún no existe.
- Un agente nunca revisa ni aprueba su propio trabajo. La revisión independiente corresponde a otro agente en una ejecución separada o a otra persona.
- La revisión debe indicar el SHA completo revisado. Cualquier commit posterior exige nueva revisión y CI sobre el nuevo `head SHA` antes del merge.
- Solo César realiza o autoriza el merge en esta etapa, tras verificar aceptación, revisión independiente y CI del SHA actual.
- No declares tareas desbloqueadas hasta comprobar que el cambio requerido se ha integrado y cumple la condición de dependencia.
