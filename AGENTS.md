# Instrucciones para agentes

Estas instrucciones se aplican a todo el repositorio.

## Antes de trabajar

- Lee [README.md](README.md), el [workflow manual](agents/README.md), la Issue asignada y sus referencias.
- Inspecciona el estado de Git y los archivos afectados. Conserva cambios ajenos.
- Usa exclusivamente `Cesar-IA-Agent` (`cesar-ia-agent[bot]`) para acceso autenticado a GitHub y autoría de commits. Lee y cumple [la política de autenticación](agents/github-authentication.md); nunca recurras a cuentas personales, de trabajo o SSH como alternativa.
- Usa una Issue como unidad de ejecución. Debe contener contexto suficiente sin depender del historial de un chat: objetivo, alcance, exclusiones, referencias, dependencias y criterios de aceptación verificables.
- Si falta una decisión necesaria, registra el bloqueo y solicita a César o al responsable de la Issue que lo resuelva. No inventes requisitos de producto ni criterios para poder cerrar la tarea.
- Desde `develop` actualizado y limpio, crea una rama exclusiva por tarea y trabaja en un checkout exclusivo: el principal o un worktree bajo `.worktrees/`, ya ignorado por Git. Varios agentes pueden escribir en paralelo siempre que cada uno use su propia rama y checkout; nunca dos agentes sobre el mismo checkout. No trabajes directamente sobre la rama de integración. Esta regla sustituye la política de escritor único del 5 de octubre de 2026; ver [la decisión 0001](docs/decisions/0001-checkouts-paralelos.md).

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

## Convenciones de código y gate local

- Identificadores y comentarios de código en inglés; documentación persistente del proyecto en español. Los textos localizados EN/ES y las copias inmutables del kit conservan sus idiomas.
- Métodos y propiedades calculadas privados en una `private extension` del tipo. Las propiedades almacenadas permanecen dentro del tipo porque Swift no permite almacenarlas en extensions. La revisión comprueba esta organización y el idioma; el lint no los garantiza.
- Configuración numérica de estilo o comportamiento en un `enum Constants` con `static let`, nombres que expliquen su significado y alcance local al tipo. No extraer cifras evidentes de aserciones, identidades matemáticas ni copy como si fueran configuración, ni crear un contenedor global genérico.
- Mantener Swift Concurrency y protocolos nombrados por capacidad, sin imports de Combine ni sufijo `Protocol`. SwiftLint comprueba estas dos reglas y números mágicos; su regla `no_magic_numbers` es conservadora y no sustituye revisar el significado de una constante.
- Ejecutar `make setup` para herramientas de calidad fijadas en la caché ignorada del checkout. No instala hooks ni cambia herramientas o credenciales globales. `make format` modifica Swift y se ejecuta antes de commit; comprobar idempotencia con `make format-check`.
- Antes de publicar/entregar un SHA que cambie Swift o configuración de build, ejecutar `make verify`: formato/lint estrictos sin corregir fuentes, kit/helper/whitespace, unit tests + smoke de un iPhone, análisis y Release sin signing. Solo crea artefactos ignorados y un simulador propio que limpia al terminar. No incorpora la batería manual iPad/rotación.
- Para cambios solo documentales, ejecutar checks de documentación/kit/whitespace pertinentes, sin Xcode innecesario. Después de un nuevo commit repetir los checks afectados y exigir CI/revisión independientes del nuevo SHA.

## Entrega y revisión

- Explica qué cambió y vincula cada criterio de aceptación con evidencia o un procedimiento reproducible de validación.
- Ejecuta los checks disponibles y los apropiados al cambio. Distingue checks ejecutados, pendientes y no aplicables; no afirmes haber compilado o probado una app que aún no existe.
- Un agente nunca revisa ni aprueba su propio trabajo. La revisión independiente corresponde a otro agente en una ejecución separada o a otra persona.
- La revisión debe indicar el SHA completo revisado. Cualquier commit posterior exige nueva revisión y CI sobre el nuevo `head SHA` antes del merge.
- Solo César realiza o autoriza el merge en esta etapa, tras verificar aceptación, revisión independiente y CI del SHA actual.
- No declares tareas desbloqueadas hasta comprobar que el cambio requerido se ha integrado y cumple la condición de dependencia.
