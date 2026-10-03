# Arquitectura

HealthGoals dispone de un bootstrap nativo SwiftUI sin dependencias externas, con un target de app y otro de UI tests. Deployment mínimo iOS/iPadOS 26, iPhone/iPad y todas las orientaciones, según la [Issue #8](https://github.com/cesarg88/HealthGoals/issues/8). La vista técnica no define arquitectura ni comportamiento de producto. HealthKit y persistencia siguen pendientes de sus tareas.

Añadir documentación técnica aquí cuando una tarea requiera una decisión concreta. Documentar el comportamiento real y las restricciones relevantes; no anticipar una arquitectura completa.

Las decisiones con alternativas y consecuencias duraderas se registran en [decisiones](../decisions/README.md). Los comandos de build/tests de simulador y sus límites están en el [README](../../README.md#build-y-tests-de-simulador).
