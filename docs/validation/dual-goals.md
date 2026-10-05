# Validación en dispositivo — dos objetivos y edición activa

Entrega de [Issue #22](https://github.com/cesarg88/HealthGoals/issues/22). César valida la integración real; tests y CI no sustituyen Salud, teclado, VoiceOver ni persistencia en una instalación anterior.

## Preparación

- Abrir `HealthGoals.xcodeproj` en `/Users/cesargonzalez/Documents/HealthGoals`, rama `feature/22-dual-goals`, scheme `HealthGoals`. No hay worktree adicional.
- Seleccionar el iPhone y configurar localmente Team `Cesar Gonzalez (Personal Team)` y bundle ID `com.example.HealthGoals`. No incorporar cambios locales de signing ni datos personales a la PR.
- Para migración, primero instalar sobre la versión anterior con objetivo aceptado, sin borrar la app. Para onboarding limpio, eliminar/reinstalar después; esto borra únicamente preferencias de la app, no datos de Salud.
- Disponer de información accesible de las métricas que se quieran probar. Autorizar ambas lecturas no garantiza que haya cuatro acumulados semanales o 28 diarios utilizables. El intervalo elegido en el panel nativo puede limitar el histórico.
- No publicar valores, capturas con datos personales ni modificar Salud o el reloj para forzar un estado.

## Recorrido real

| Punto | Acción | Resultado esperado |
| --- | --- | --- |
| 1. Actualización | Instalar sobre la versión anterior con un objetivo activo y abrir. | Home conserva la métrica y el valor aceptado; vuelve a consultar Salud sin bienvenida ni autorización automática. |
| 2. Un objetivo | Instalación limpia: Caminar más → Continuar → autorización → Tu punto de partida. Aceptar sin Añadir Actividad. | Solo aparece propuesta de pasos y Home contiene únicamente Pasos. No se activa la otra métrica. |
| 3. Segunda explícita | Instalación limpia: llegar a Tu punto de partida y tocar Añadir Actividad. | Aparece una segunda sección con carga/estado propio. El baseline y borrador de pasos se conservan. No se solicita autorización adicional. |
| 4. Dos propuestas | Con ambas propuestas disponibles, ajustar Actividad y cancelar; luego ajustar y aplicar. Aceptar con Usar estos objetivos. | Cancelar conserva su propuesta. Aplicar cambia solo el borrador de Actividad; todavía no activa objetivos. Aceptar muestra ambas tarjetas con sus valores, progreso, restante y ritmo individuales. |
| 5. Segunda sin datos | Si se reproduce una métrica sin cuatro acumulados semanales aptos, añadirla. Reintentar o tocar Mantener solo el objetivo principal. | La primera propuesta permanece. No se inventa una segunda ni se interpreta ausencia como denegación. Para aceptar solo la primera se retira explícitamente la segunda; con ambas seleccionadas, aceptación exige ambas propuestas aptas. |
| 6. Home independiente | Con dos objetivos, abrir y tocar Actualizar; expandir la explicación del ritmo. | Cada tarjeta conserva unidad, objetivo, progreso, restante, ritmo y fecha de consulta propios. No hay ritmo global. La explicación es secundaria; abrirla no consulta Salud. Si una lectura falla o carece de datos, la otra sigue siendo útil. |
| 7. Cancelar edición activa | En Home tocar Ajustar bajo una métrica; modificar la entrada y cancelar. | Home conserva el valor activo y la otra tarjeta. Campo y unidad son visibles; el copy explica efecto en la semana actual. |
| 8. Guardar edición activa | Editar uno de los valores a otro entero positivo y guardar. Probar también vacío, cero, negativo y texto no numérico si el teclado lo permite. | Entrada no válida deshabilita Guardar cambios. Guardar modifica inmediatamente esa meta en la semana actual, conserva acumulado y fecha observados, recalcula restante y ritmo. La otra meta permanece. No hay cambio programado para la siguiente semana. |
| 9. Reinicio con dos | Cerrar completamente y abrir después de editar. | Se recuperan ambas definiciones, incluido el valor editado. Progreso/patrón se consultan de nuevo, sin petición automática de permisos. |
| 10. Borrar uno | Ajustar una métrica → Eliminar objetivo. Cancelar confirmación; repetir y confirmar. | Cancelar conserva el objetivo. Confirmar elimina exclusivamente esa métrica y Home continúa con la otra. Los datos de Salud no cambian. |
| 11. Borrar último | Eliminar el objetivo restante con confirmación; cerrar y abrir. | Home vacío, sin ceros ficticios ni objetivos creados automáticamente. CTA Elegir un objetivo; el vacío persiste tras relanzar. |
| 12. Recuperar desde vacío | Elegir un objetivo. Seleccionar intención y continuar; aceptar propuesta disponible. Repetir cancelando antes de aceptar. | Solo selección, sin promesa de bienvenida ni Conectar con Salud; va directamente a baseline/propuesta real. No repite autorización automática. Cancelar regresa a Home vacío. Aceptar crea solo lo elegido; se puede añadir segunda explícitamente en esta propuesta. |
| 13. Orden inverso | Instalación limpia: Moverme más y después Añadir Pasos. | La propuesta principal es Actividad; Pasos solo aparece bajo acción explícita. Ajustar/aceptar no mezcla métricas ni unidades. Máximo dos, una por métrica. |
| 14. Presentación | EN/ES desde ajustes nativos de iOS, Light/Dark, texto ampliado, VoiceOver, paisaje; iPad si está disponible. | Tarjetas y acciones legibles mediante scroll, selección y estados no dependen del color. En la hoja, teclado no impide acceder a Guardar/Aplicar/Cancelar. Confirmación nativa identifica la métrica; unidad visible y acciones accesibles. |

## Revisar acceso en Salud y revalidar observaciones

Cuando una métrica muestra insuficiencia, la ayuda indica que puede faltar historial o acceso. Reintentar vuelve a consultar; no abre la autorización nativa ni permite saber si se denegó lectura. Un error técnico conserva su explicación de lectura fallida sin atribuirlo a permisos.

Para revisar manualmente el acceso: abrir **Salud → Resumen → imagen de perfil → Privacidad → Apps → HealthGoals**. Revisar la lectura de **Pasos** y de **Energía activa** (la métrica que HealthGoals presenta como Actividad). La ruta pertenece a la interfaz de Salud; seguir la lista de aplicaciones del perfil si la versión del sistema presenta el nombre ampliado «Apps y servicios». Apple documenta esta gestión en [Seleccionar qué apps compartirán información con Salud](https://support.apple.com/es-es/104997). No hay enlace privado ni nueva pantalla en HealthGoals.

Después de modificar el acceso deseado, volver a Tu punto de partida y tocar Reintentar en la sección de esa métrica. Permitir lectura no garantiza histórico suficiente; si sigue sin cantidades aptas, conservar insuficiencia sin diagnosticar denegación. No cambiar datos de Salud para obtener una propuesta.

Revalidar los puntos afectados por el reporte físico:

- **3:** con solo Pasos autorizado inicialmente, añadir Actividad. Comprobar ayuda neutral de esa métrica, abrir Salud por la ruta anterior, revisar acceso y volver a Reintentar. La primera propuesta se conserva. Si hay datos aptos, aparece propuesta real; si no, registrar la insuficiencia restante.
- **4:** con dos propuestas aptas, anotar mentalmente el valor de Actividad, abrir Ajustar, introducir un entero positivo diferente y tocar Aplicar. Al volver, comprobar que el número de esa propuesta es el editado y el de Pasos no cambia. Aplicar guarda un borrador, sin marca de aceptación por métrica; **Usar estos objetivos** activa conjuntamente lo elegido. No publicar números personales en el reporte.
- **6:** con Home disponible, tocar Actualizar varias veces. El indicador de consulta se muestra en la cabecera de cada tarjeta y conserva su espacio aun estando oculto; no debe aparecer/desaparecer una fila que desplace Ajustar, explicación o Actualizar. Datos, restante y ritmo pueden cambiar por lectura real, conservando el timestamp de la observación mientras se consulta. Cambio natural de longitud de los datos o un estado de error/insuficiencia tiene contenido diferente y no se confunde con el salto anterior del indicador.

El reporte inicial de César sobre el SHA `23a25fe6c88ac6e490485a493bde97d30ebddd23` confirma **1, 2 y 7–14 OK**; **5 no probado**, sin excepción de aceptación atribuida por Engineering. Las observaciones 3, 4 y 6 están registradas en [Issue #22](https://github.com/cesarg88/HealthGoals/issues/22#issuecomment-5993489253). Este historial se conserva; una corrección requiere nuevo SHA, CI/revisión y revalidación de los casos afectados. No se declara físicamente validada la corrección por pasar tests.

## Comparación y límites

El baseline utiliza cuatro bloques de siete días completos anteriores a hoy; Home cuenta la semana local lunes–lunes incluyendo el parcial de hoy. Cambiar la meta no convierte el baseline histórico en progreso actual. Comparar restante con la meta de la tarjeta y su acumulado de la misma consulta: `máximo(0, meta − acumulado)`. El ritmo conserva las reglas de #21 y se recalcula para cada meta; no es una cuota diaria.

Los objetivos se almacenan como definiciones (métrica/entero). No se guardan baseline, cantidades HealthKit, progreso, patrón ni pacing. El borrador de segunda métrica antes de aceptación permanece en memoria: relanzar durante la propuesta recupera la intención/etapa segura y consulta otra vez la principal; la segunda se añade de nuevo explícitamente. La reelección desde Home vacío conserva el contexto de onboarding completado incluso si se cierra durante la selección o propuesta.

Un error técnico de una lectura, ausencia exclusiva de una métrica o cada combinación de ritmo pueden no reproducirse razonablemente con el dispositivo disponible. Registrar «no probado/no reproducible» en lugar de inventar evidencia. Los tests aislados cubren fallos independientes, edición durante respuesta pendiente y eliminación que descarta respuestas tardías. No se añade un modo de datos ficticios a producción para estos casos.

La fecha significa fin de consulta de progreso; no confirma sincronización del Watch. Sin observer, temporizador, background ni resumen semanal en esta entrega. Eliminar un objetivo no borra Salud ni revoca sus permisos. Denegar lectura puede producir ausencia, pero HealthGoals no identifica su estado ni vuelve a solicitar autorización automáticamente al reeligir.

## Registro de aceptación

Responder por punto con OK, incidencia o no probado, sin cifras personales. Gate automático, revisión independiente y CI deben corresponder al SHA actual de la PR; el merge queda en manos de César. La revalidación física de los casos afectados sigue pendiente hasta el reporte de César.
