# Registro de decisiones

Registrar aquí decisiones duraderas que afecten a futuras tareas y cuyo motivo no resulte evidente en el código o los requisitos. Los cambios rutinarios se explican en la Issue o PR; no necesitan un documento adicional.

Mantener una fuente canónica por propósito: one-pager para visión y principios; MVP scope para comportamiento y alcance; Figma y documentación de diseño para UX visual; Issues para ejecución; PRs para cambios y evidencia. No duplicar decisiones rutinarias de producto como ADRs. Este registro conserva solo razones duraderas no evidentes, por ejemplo de arquitectura, HealthKit, persistencia o StoreKit. La documentación persistente no debe referenciar turnos ni identificadores internos de conversaciones; usar referencias al repositorio, Issues y PRs.

Usar archivos `NNNN-titulo-breve.md` con numeración consecutiva y estos campos:

- Título, fecha y estado: propuesta, aceptada o sustituida.
- Contexto y problema.
- Decisión y responsable de aceptarla.
- Alternativas consideradas y consecuencias.
- Referencias a la Issue, PR y documentos relacionados.

No presentar propuestas como decisiones aceptadas. Al sustituir una decisión, conservar el registro anterior y enlazar la nueva.
