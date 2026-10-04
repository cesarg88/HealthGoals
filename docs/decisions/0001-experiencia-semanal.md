# Experiencia semanal del MVP

Fecha: 2026-10-04. Estado: aceptada para las decisiones enumeradas; pendientes identificados aparte.

## Contexto y problema

Las fuentes de producto incluían reparto diario en Home y confirmación Mantener para la nueva semana. César confirmó ajustes de comportamiento en healthGoals-design, turno `01a10627-aacf-7950-a1bd-024f97fae511`, verificados por Product y registrados en la Issue #14. Discovery y alcance siguen cerrados.

## Decisión y responsable

Responsable de aceptación: César, con healthGoals-Product.

- Home conserva gap semanal, sin reparto lineal diario.
- La explicación del ritmo es secundaria; se conserva el estado de ritmo personal.
- Los objetivos continúan automáticamente con el mismo valor al cambiar de semana, sin confirmación Mantener ni incrementos automáticos. El resumen permite revisión y ajuste.
- La primera semana utiliza la semana actual completa con datos desde lunes, sin prorrateo (D02 resuelta).
- La segunda métrica es opcional, máximo dos objetivos; Home muestra ambos simultáneamente si se eligieron ambos.
- Las etiquetas de intención y métrica semanal son propuestas de wording, no literales obligatorios.

## Alternativas y consecuencias

Se sustituyen el reparto diario de Home y el paso obligatorio de confirmación de continuidad descritos anteriormente. La nueva semana no depende de abrir el resumen. No se fija un algoritmo de ritmo ni umbrales, y no se aprueba por anticipado el diseño visual final.

Siguen pendientes D01 (zona horaria, cambios de hora y viajes) y el efecto temporal de editar objetivos. Esta decisión no los resuelve.

## Referencias

- [Issue #14](https://github.com/cesarg88/HealthGoals/issues/14): encargo y evidencia de autoridad.
- [Issue #12](https://github.com/cesarg88/HealthGoals/issues/12) y [PR #13](https://github.com/cesarg88/HealthGoals/pull/13): trabajo de diseño separado, sin asumir integración por estar abierto.
- [One-pager](../product/one-pager.md) y [MVP scope](../product/mvp-scope.md): fuentes actualizadas.
