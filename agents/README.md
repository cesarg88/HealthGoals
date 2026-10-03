# Workflow manual

`Issue → Implementer → PR → Reviewer → changes requested → Implementer → Review → CI → Merge`

CI puede ejecutarse en paralelo a la revisión. El merge requiere que ambos correspondan al mismo `head SHA` actual.

## Responsabilidades

- **César y healthGoals-Product, responsables de producto:** deciden prioridades, experiencia, alcance y aceptación. César realiza o autoriza merges.
- **Engineering, líder técnico y orquestador:** convierte las prioridades aprobadas en Issues y entregas verificables, coordina implementación y revisión independiente, resuelve decisiones técnicas rutinarias y escala a Product las que afectan al producto.
- **healthGoals-design, diseño/UX:** desarrolla los flujos y estados dentro del alcance aprobado y coordina decisiones de experiencia con Product.
- **healthgoals-infra, infraestructura:** prepara y verifica herramientas, CI y configuración del repositorio dentro de sus Issues.
- **Implementer:** ejecuta una Issue en su rama y checkout/worktree exclusivos, actualiza documentación y entrega una PR pequeña con evidencia.
- **Reviewer:** lee la Issue, referencias, diff y evidencia; comprueba criterios, alcance y riesgos. No puede ser el autor ni el mismo agente que implementó el cambio.

## Coordinación entre chats

César autoriza de forma permanente los mensajes directos, handoffs y consultas útiles entre Product, Engineering, Design e Infra. No se solicita permiso para cada mensaje. Esta autorización permite coordinar el trabajo aprobado; no amplía permisos de merge, gasto, publicación ni alcance de producto. Solo César realiza o autoriza merges.

| Rol | Chat | Identificador |
| --- | --- | --- |
| Product | healthGoals-Product | `01a10068-087a-7061-aa0d-599e77078e28` |
| Engineering | líder técnico y orquestador | `01a103c7-bc58-7ec3-84b9-285095f112ee` |
| Design | healthGoals-design | `01a1006d-83d1-7520-8ac9-77b42e754d1b` |
| Infra | healthgoals-infra | `01a0fceb-8d06-74b0-b2a7-83fff94950f4` |

Las decisiones necesarias se conservan en Issues y documentación antes de depender de ellas; los mensajes no sustituyen ese registro. La [Issue #9](https://github.com/cesarg88/HealthGoals/issues/9) registra esta autorización y los roles confirmados.

## Procedimiento

1. **Preparar la Issue.** Usar la plantilla de tarea. Enlazar el contexto persistente, detallar alcance y exclusiones, escribir criterios comprobables y enumerar dependencias con su condición de resolución. Usar «Ninguna» cuando no existan. César confirma que está lista para ejecutar.
2. **Aislar el trabajo.** Partir de la rama de integración actualizada (`develop` inicialmente), salvo que la Issue indique otra base. Usar una rama como `type/123-descripcion` y un checkout/worktree exclusivo. No reutilizarlo mientras otro agente o proceso lo necesite o haya trabajo pendiente sin preservar.
3. **Implementar y validar.** Ejecutar solo el alcance asignado. Actualizar los documentos afectados y anotar comandos, resultados y limitaciones. Si aparecen decisiones bloqueantes, registrarlas en la Issue para que César las resuelva.
4. **Abrir la PR.** Usar la plantilla, enlazar la Issue y seleccionar la base acordada. Si la PR no completa toda la Issue, identificar qué queda pendiente. No depender del cierre automático de Issues al fusionar en una rama distinta de la predeterminada.
5. **Revisión independiente.** César asigna otra persona o agente. El reviewer registra el SHA completo, evalúa cada criterio y devuelve aprobación o cambios solicitados con ubicación, motivo y validación esperada. Un agente que no pueda emitir una aprobación formal en GitHub deja un informe identificado; César comprueba su independencia y decide conforme a las reglas de GitHub.
6. **Iterar.** El implementer atiende los hallazgos y explica cómo los resolvió. Cada commit nuevo invalida la revisión anterior para el merge: el reviewer vuelve a revisar el nuevo SHA y CI vuelve a ejecutarse. Los comentarios previos permanecen como historial.
7. **Verificar y fusionar.** César comprueba que el SHA aprobado coincide con el head actual de la PR, que los checks de ese SHA terminaron correctamente y que se cumplen los criterios sin bloqueos pendientes. Después realiza o autoriza el merge. Si cambia el head, repetir la verificación.
8. **Resolver dependencias.** Tras confirmar el merge, César actualiza la Issue completada y las Issues dependientes. Una tarea se desbloquea únicamente cuando todas sus condiciones de dependencia se cumplen; no basta con abrir o aprobar una PR.

## Kit reutilizable

HealthGoals consume [agent-engineering-kit](https://github.com/cesarg88/agent-engineering-kit) en el commit integrado `a7d77a422bbdf0da5a02fe68b2eb4ec32352c45a`. [kit-lock.json](kit-lock.json) registra la procedencia, las rutas originales y SHA-256 de las siete copias exactas. Se conservan en inglés, el idioma del kit.

- Roles: [coordinator](roles/coordinator.md), [implementer](roles/implementer.md), [reviewer](roles/reviewer.md).
- Skills del repositorio: [implement-issue](../.agents/skills/implement-issue/SKILL.md) y [review-pr](../.agents/skills/review-pr/SKILL.md). Leerlas directamente si el cliente no las descubre; no requieren instalación global.
- Helper: `tools/agent-github/agent_github.py`; configuración y operaciones en [la política local](github-authentication.md).

Para actualizar el kit, comprobar primero el merge upstream, recuperar las siete rutas originales del nuevo SHA, sustituir las copias y actualizar SHA/hashes del manifiesto en una Issue dedicada. Revisar también cualquier cambio de configuración requerido. CI detecta divergencias de las copias respecto al manifiesto; la revisión independiente verifica la procedencia frente al SHA upstream. No se descarga el repositorio privado durante CI.

## CI y límites actuales

`Repository checks / whitespace` comprueba errores de whitespace introducidos por la PR usando su head SHA explícito. Es un check de higiene. `Repository checks / agent-kit` ejecuta `python3 scripts/check-agent-kit.py` y `python3 -m unittest discover -s tests -v` sobre el mismo head explícito; valida las copias y el comportamiento del helper. `iOS / ios-build-test` compila el bootstrap y ejecuta pruebas de lanzamiento y rotación en simuladores iPhone/iPad con `scripts/test-ios.sh`, también sobre el head explícito. Los requisitos y límites están en el [README](../README.md#build-y-tests-de-simulador).

`develop` tiene protecciones administradas en GitHub; los archivos del repositorio no las aplican automáticamente. Añadir `ios-build-test` como obligatorio requiere observarlo verde y coordinar el cambio con César. La revisión independiente del SHA completo y la autorización de merge de César siguen siendo controles manuales.

Los roles y skills apoyan el flujo manual. No automatizan asignaciones, desbloqueos ni merges.
