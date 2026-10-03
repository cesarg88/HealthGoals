# HealthGoals

HealthGoals es una app iOS basada en HealthKit. Discovery completado; decisión: **BUILD**.

> HealthGoals utiliza la actividad reciente del usuario para ayudarle a establecer objetivos semanales sencillos y después le dice automáticamente cómo va y exactamente qué le queda para cumplirlos.

Core loop: `Intención → Baseline → Plan → Progress → Gap → Adapt`.

## Estado actual

Este repositorio contiene la base documental, el workflow manual y las herramientas reutilizables de agentes. Todavía no hay proyecto Xcode, código de producto ni comandos de build de la app. Los checks de infraestructura verifican la integridad del kit y su helper de GitHub.

La definición de producto está en [one-pager.md](docs/product/one-pager.md) y el alcance inicial en [mvp-scope.md](docs/product/mvp-scope.md).

## Punto de entrada

- [AGENTS.md](AGENTS.md): instrucciones comunes para agentes de coding.
- [Producto](docs/product/README.md): alcance, requisitos y diseño.
- [Arquitectura](docs/architecture/README.md): estado y documentación técnica.
- [Decisiones](docs/decisions/README.md): registro de decisiones duraderas.
- [Workflow manual](agents/README.md): de Issue a merge y responsabilidades.

GitHub es la fuente de verdad: las Issues definen unidades de ejecución, las PRs contienen cambios y evidencia, y los documentos del repositorio conservan el contexto compartido. Las decisiones tomadas en conversaciones deben trasladarse al repositorio o a la Issue antes de depender de ellas.

## Cómo empezar

1. Leer `AGENTS.md` y los documentos vinculados en la Issue.
2. Confirmar que la Issue tiene alcance y criterios de aceptación verificables y que sus dependencias están resueltas.
3. Trabajar en una rama y checkout/worktree exclusivos siguiendo el workflow manual.

El líder técnico coordina las asignaciones y revisiones con Product, Design e Infra según las [responsabilidades y autorización de coordinación](agents/README.md#coordinación-entre-chats). César realiza o autoriza los merges. Los [roles y dos skills del kit](agents/README.md#kit-reutilizable) apoyan ese workflow manual; no hay orquestación automática ni protección de ramas configurada por estos archivos.
