# Validación en dispositivo — ritmo personal semanal

> Guía histórica de su entrega. Para el onboarding vigente desde #29 (selección de una o ambas métricas, autorización solo de los tipos elegidos y just-in-time al añadir), usar [selección y autorización por métrica](metric-selection.md). Las observaciones físicas antiguas no acreditan un SHA posterior ni el nuevo recorrido; los casos de edición, eliminación y ritmo siguen siendo referencias de regresión.

Entrega: [Issue #21](https://github.com/cesarg88/HealthGoals/issues/21). Complementa la [guía de objetivo y Home](weekly-goal-home.md). La evidencia automática valida cálculo/estados; la consulta real y la comprensión requieren el iPhone de César.

## Preparación

1. Abrir `HealthGoals.xcodeproj` en `/Users/cesargonzalez/Documents/HealthGoals`, checkout principal y rama candidata `feature/21-personal-pacing`. Registrar el SHA indicado en la PR antes de probar. No crear otro worktree.
2. Seleccionar scheme `HealthGoals`, el iPhone y `Cesar Gonzalez (Personal Team)` en Signing & Capabilities. Mantener bundle `com.example.HealthGoals`. La firma es configuración local; no incluir certificados/perfiles ni cambios de Team en la PR.
3. Ejecutar desde Xcode. Para conservar el objetivo de la entrega anterior, instalar sobre la app existente. Para cambiar la intención principal durante estas pruebas, eliminar/reinstalar y recorrer onboarding; esta entrega no añade edición activa ni segunda métrica.
4. Cuando iOS permita limitar el histórico a los últimos 30 días, esa opción puede cubrir la ventana de 28 días completos, pero no garantiza cantidades utilizables para cada día. La app no conoce el estado READ ni debe deducirlo.

## Recorrido real

| Prueba | Acción | Resultado esperado |
| --- | --- | --- |
| 1. Actualización | Instalar sobre la versión con objetivo aceptado | Abre directamente Home; mantiene objetivo e intención y consulta progreso/patrón sin autorización automática. |
| 2. Instalación limpia | Elegir Caminar más, finalizar Salud, aceptar propuesta o borrador ajustado | Home muestra Pasos, restante real y acumulado de la semana activa, y después un estado de ritmo en esa misma tarjeta. No activa Actividad. |
| 3. Estado y coherencia | Observar estado con historial accesible de 28 días completos | Un texto: A tu ritmo, Por delante…, Un poco por debajo… o Todavía no podemos estimar…; Objetivo completado tiene prioridad cuando el progreso alcanza la meta. No presenta diagnóstico de permiso, Watch o inactividad. |
| 4. Explicación | Abrir Cómo interpretamos tu ritmo; cerrar y volver a abrir | Empieza contraída. Explica la distribución habitual semanal y días distintos; no muestra fórmulas, porcentajes esperados, horas ni cuotas diarias. Expandir no altera objetivo, progreso o restante. |
| 5. Semana flexible | Si tu actividad habitual se concentra en fin de semana, valorar el texto en un día anterior | La comparación sigue tu distribución histórica hasta el inicio del día local actual, sin esperar una séptima parte diaria. Si hoy es lunes, el esperado es cero; el progreso parcial de hoy puede mejorar el estado. |
| 6. Actualizar | Pulsar Actualizar varias veces o salir/volver a primer plano | Se vuelve a consultar. No se duplican operaciones concurrentes ni aparecen prompts de Salud; el objetivo permanece. El restante sigue siendo objetivo menos progreso actual, nunca una cuota derivada del ritmo. |
| 7. Restauración | Cerrar completamente la app en Home y abrirla otra vez | Mantiene la definición del objetivo, vuelve a consultar y recalcula el ritmo. No recupera valores de Salud ni patrón de preferencias, ni pide autorización automáticamente. |
| 8. Patrón insuficiente | Si puede reproducirse razonablemente un historial incompleto manteniendo actividad semanal accesible | Ritmo desconocido neutral y progreso/restante siguen disponibles. No convertir un día sin cantidad en cero. Si restringir Salud oculta también el progreso, Home muestra insuficiencia de progreso; ese caso no demuestra patrón insuficiente aislado. |
| 9. Completado | Solo si el progreso real puede alcanzar el objetivo aceptado | Objetivo completado tiene prioridad con o sin patrón; restante cero y progreso real conservado. No aumenta la meta. No hace falta alterar datos de Salud ni el reloj para forzar este caso. |
| 10. Otra métrica | Si disponible, reinstalar y elegir Moverme más | La misma experiencia usa energía activa, kcal y patrón de Actividad. La selección no cambia silenciosamente a pasos. |
| 11. Idioma y presentación | Idioma de la app EN/ES en ajustes nativos; Light/Dark; texto aumentado, landscape y VoiceOver | Estado y explicación traducidos, legibles, sin truncamiento deliberado ni dependencia del color. Expandir/contraer es accesible; la barra decorativa no duplica progreso. |

## Cómo informar

Indicar pruebas OK o incidencias; para coherencia, basta «coherente», «no coherente» o «no comprobable». No publicar cifras, capturas de Salud, historial ni muestras personales en GitHub. Conservar solo el SHA y condiciones generales que expliquen una incidencia.

Una comparación con Salud no tiene que coincidir con sus gráficos semanales: la fuente del patrón es una ventana móvil de 28 días completos anteriores a hoy, y Home usa la semana local lunes–lunes. Cada weekday reúne cuatro observaciones; la media da el peso de ese día. Se compara con el inicio del día, no con horas transcurridas. Durante un día, nueva actividad solo puede mejorar el estado si se mantienen objetivo y patrón.

La cantidad ausente no es cero. Una cantidad explícita cero sí se conserva, pero el patrón exige 28 cantidades finitas no negativas y una semana histórica positiva. Tener cuatro agregados semanales para baseline no implica que todos los días tengan cantidad; por ello es posible obtener propuesta y progreso con ritmo desconocido.

## Límites y evidencia pendiente

No se puede forzar de forma fiable un fallo técnico ni todos los estados de ritmo con un historial real. Registrar «no reproducible» cuando corresponda; los tests aislados cubren esos estados, el error de patrón sin perder gap, tolerancia/fronteras y cambios de día/semana/zona durante consultas. No modificar el reloj ni crear datos de Salud para aprobar una prueba. Sin patrón utilizable, la coherencia de un ritmo conocido queda pendiente de otro dispositivo/historial adecuado; no inventar evidencia.

El timestamp de Home describe consulta de progreso completada, no sincronización del Watch. No hay background, observador ni temporizador: actualizar, primer plano y restauración recalculan. Si llega actividad nueva mientras consultamos, el progreso puede variar; no atribuir esa variación al ritmo. Comparar el mismo acumulado/objetivo para comprobar gap, no números tomados en momentos diferentes.

Automático: `make format`, `make format-check`, `make verify` y los checks CI de la PR sobre el SHA actual. Revisión independiente registra el SHA completo. Pendiente físico: recorrido anterior y aceptación de César; solo César realiza o autoriza merge. No se acredita dispositivo por un simulador verde.
