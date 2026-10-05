# Validación de propuesta y primera Home semanal

[Issue #20](https://github.com/cesarg88/HealthGoals/issues/20). Esta guía valida la propuesta, el ajuste del borrador y el progreso real de un único objetivo. No valida ritmo personal, segunda métrica, resumen, edición activa ni funciones de #21.

## Preparación

Abrir `HealthGoals.xcodeproj` en el checkout del candidato de la PR, scheme `HealthGoals`, iPhone real. Seleccionar localmente `Cesar Gonzalez (Personal Team)` en Signing & Capabilities y conservar `com.example.HealthGoals`. No versionar cambios personales de firma. Build sin firma de CI no acredita instalación.

Si la instalación conserva S03 de la entrega anterior, se vuelve a consultar el baseline y aparece la propuesta. Para repetir ambas intenciones después de aceptar, eliminar/reinstalar la app restablece su configuración local. No elimina datos de Salud; puede conservar autorizaciones nativas. No hay un botón de reinicio ni edición activa en esta entrega.

## Recorrido con datos reales

1. Elegir Caminar más, completar la solicitud nativa y esperar S03. Debe mostrar media real de cuatro bloques completos de siete días, excluyendo hoy. Con baseline positivo aparece una propuesta calculada con un 5 % adicional y redondeo a centena de pasos. Si ese redondeo no supera baseline, usa el entero inmediatamente superior al candidato. No esperar los números ilustrativos de Figma.
2. Abrir Ajustar: escribir un entero positivo. Probar vacío, cero, negativo o decimal mediante pegado; Aplicar debe quedar deshabilitado. Cancelar conserva el borrador. Aplicar vuelve a S03 con el valor nuevo sin activar todavía el objetivo. La explicación de crecimiento corresponde a la propuesta inicial; después del ajuste el usuario decide libremente un entero positivo.
3. Pulsar Usar este objetivo: entrar directamente en Home. No se activa otra métrica.
4. Comprobar Esta semana, días restantes, métrica y valor aceptado. La semana comienza lunes a las 00:00 locales y termina el lunes siguiente. Cuenta la actividad accesible desde ese lunes hasta la consulta, aunque el objetivo se aceptó más tarde; no prorratea. Lunes indica siete días, viernes tres y domingo uno.
5. Comparar privadamente el acumulado con Salud para esa métrica/semana. El restante debe corresponder a objetivo menos progreso, nunca negativo. La cifra mantiene precisión interna aunque se muestra sin decimales. No se exige coincidencia exacta con un gráfico de Salud cuyos intervalos, fuentes o actualización difieran.
6. Actualizar tras actividad nueva/sincronización de Salud: volver a consultar, mostrar timestamp de consulta terminada y recalcular restante. El timestamp no certifica sincronización del Watch ni cobertura diaria. Loading no reutiliza un número como si fuera actual; insuficiencia/error no equivale a cero ni a denegación de lectura.
7. Cerrar completamente y reabrir: ir a Home, conservar objetivo y consultar otra vez. No repetir onboarding ni pedir Salud automáticamente. Salir y regresar a la app también consulta; no hay actualización continua ni background.
8. Repetir con Moverme más tras eliminar/reinstalar; comprobar energía activa en kcal y redondeo a decena para la propuesta. Si faltan datos accesibles, aceptar insuficiencia neutral: no se ofrece objetivo manual sin baseline.
9. EN/ES mediante idioma nativo de la app/sistema; Light/Dark; texto aumentado razonable, VoiceOver y landscape. Deben permanecer visibles unidades, estados y acciones mediante scroll. No hay selector propio de idioma.
10. Si es reproducible con datos ya disponibles, aceptar un objetivo positivo inferior al progreso real para comprobar Objetivo completado, restante cero y acumulado real que puede superar objetivo. La app no aumenta la meta. No modificar ni publicar datos de salud para fabricar evidencia.
11. Al abrir una nueva semana, el valor aceptado continúa y se consulta el intervalo nuevo, sin confirmación ni resumen. Si no es práctico esperar, registrar pendiente físico; las fechas/calendario se prueban con tests aislados. Un cambio de zona horaria recalcula los límites en la zona local actual; v1 no reconcilia viajes históricos.
12. Cuando iOS permita reproducirlo, limitar lectura desde Salud y Actualizar: información desconocida/insuficiente no debe afirmar «permiso denegado». Un error técnico real puede no ser reproducible; error/reintento se verifican con lector sustituido, sin afirmar evidencia física inexistente.

## Evidencia y límites

Reportar solo recorrido correcto/incidencia, coherencia/no comprobable, restauración correcta/incidencia, completado comprobado/no reproducible e idioma/adaptación correctos/incidencias. No adjuntar cifras, capturas ni historial personal de salud a Issues/PRs.

`make verify` comprueba tests de motor, calendario y estado con lector pequeño sustituido, más lanzamiento iPhone, análisis y Release sin firma. Las capturas de S03 usan datos ficticios exclusivamente en tests. ImageRenderer no acredita scroll/teclado y Home puede iniciar su tarea de lectura al renderizarse: sus estados visuales requieren validación física, mientras su lógica tiene tests aislados. La validación de HealthKit y firma en iPhone corresponde a César; ni simulador ni CI la sustituyen. Ausencia de una cantidad no identifica permiso READ, Watch o inactividad; un cero explícito es distinto de ausencia. Cuatro agregados de baseline no garantizan cobertura diaria.
