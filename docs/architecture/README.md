# Arquitectura

HealthGoals es una app nativa SwiftUI, Swift 6, sin dependencias externas. Deployment mínimo iOS/iPadOS 26, iPhone/iPad y orientaciones declaradas, según la [compatibilidad de producto](../product/mvp-scope.md#2-usuario-objetivo). El scheme compartido incluye app, tests de lógica y UI tests.

La [Issue #16](https://github.com/cesarg88/HealthGoals/issues/16), integrada por PR #17, introdujo S01 Intención → S02 Salud → autorización → S03. `ActivityIntention` define walking/activity y su métrica sin depender de traducciones. `OnboardingModel` es observable y aislado al actor principal porque administra estado de interfaz. La vista usa controles SwiftUI, scroll y una columna adaptable.

## Autorización y lectura

`HealthAuthorizing` sustituye únicamente disponibilidad y solicitud en tests. `HealthAuthorization` conserva un HKHealthStore por instancia, comprueba disponibilidad en runtime y solicita lectura de pasos/energía activa sin escritura. La app entrega esa misma instancia al modelo para autorización y lectura. No consulta `authorizationStatus(for:)`; terminar la solicitud permite entrar a S03 sin conocer acceso READ. Durante autorización se bloquean duplicados y navegación para evitar respuestas tardías sobre otra intención.

La [Issue #18](https://github.com/cesarg88/HealthGoals/issues/18) añade `HealthReading`, que devuelve cuatro cantidades semanales opcionales exclusivamente para la métrica principal. `HealthAuthorization` realiza un `HKStatisticsCollectionQueryDescriptor` async one-shot con `.cumulativeSum`, sin separación por fuente ni consultas de muestras crudas. HealthKit mantiene la agregación del sistema; `ActivityMetric` convierte solo pasos/count o energía activa/kilocalories. No solicita nuevos permisos ni activa escritura/background.

`BaselineWindow` construye, con Calendar y zona local actuales, cuatro períodos consecutivos de siete días desde el inicio de hoy menos 28 días naturales hasta el inicio de hoy exclusivo. Fecha y calendario se inyectan mediante dos closures pequeñas para tests; no hay Clock global. El descriptor se ancla al inicio de esa ventana y usa componentes de calendario de siete días. Se verifica que cada estadística tenga exactamente las fechas esperadas; una desalineación de calendario/zona genera error técnico, nunca una ventana aceptada silenciosamente.

Apple documenta que `statistics(for:)` devuelve cantidades nil cuando no existen muestras del intervalo, y `sumQuantity()` es opcional. Conservamos esa ausencia; una HKQuantity presente con valor cero se conserva como cero explícito. Esta distinción no demuestra cobertura diaria, inactividad ni permiso. [Contrato de estadísticas](https://developer.apple.com/documentation/healthkit/hkstatisticscollection/statistics(for:)) y [descriptor actual](https://developer.apple.com/documentation/healthkit/hkstatisticscollectionquerydescriptor) sustentan la integración.

## Cálculo y estado S03

`BaselineCalculator` es pura: exige exactamente cuatro acumulados finitos y no negativos y calcula su media aritmética conservando Double. Cualquier ausencia/cantidad no utilizable produce insuficiencia. No hay mediana, umbral de cobertura diaria, exclusión de atípicas ni progresión. No se interpreta insuficiencia como denegación READ o falta de Watch.

El modelo expone `BaselineState`: loading, available, insufficient y failed. S03 consulta al aparecer, muestra datos reales o mensajes neutrales y ofrece reintento ante insuficiencia/error. Una tarea finita propiedad del modelo administra la consulta: tareas de vista concurrentes esperan el mismo trabajo y su cancelación al desaparecer no abandona el estado loading. Tras completar, la misma sesión no repite lectura por reaparecer; el reintento explícito consulta otra vez. Una nueva instancia restaurada vuelve a loading y realiza nueva lectura sin pedir autorización automáticamente. No se introducen observadores ni consultas en background.

`BaselineView` conserva título y jerarquía de tarjeta de S03 aprobada en Figma, tipografía semántica y colores locales Light/Dark en Asset Catalog. La extensión de #20 añade propuesta/ajuste de borrador/aceptación, respetando la tarjeta y omitiendo segunda métrica. No hay design system ni rediseño de S01/S02. La presentación redondea a entero con locale, mantiene precisión interna y usa pluralización nativa del catálogo para pasos. VoiceOver combina valor/unidad; scroll y columna máxima conservan adaptación y Dynamic Type.

## Persistencia y límites

La persistencia sigue usando un diccionario UserDefaults con intención y etapa segura. S02 se guarda antes de solicitar autorización; operaciones en curso y errores no se persisten. S03 se guarda solo tras finalizar autorización sin error, sin flags de permiso. Restaurar exige una intención válida; una etapa inválida vuelve a S01. Nunca se guardan muestras, acumulados ni baseline. `PrivacyInfo.xcprivacy` declara el motivo de preferencias locales. No hay persistencia general ni cache persistente.

Textos en `Localizable.xcstrings` EN/ES y explicación nativa de lectura en `InfoPlist.strings`; entitlement HealthKit básico, sin clinical/background. La entrega de #20 añade motor puro, objetivo principal y Home, como se describe a continuación. La [validación de onboarding](../validation/onboarding-healthkit.md), [baseline en hardware](../validation/healthkit-baseline.md) y [README](../../README.md#build-y-tests-de-simulador) explican cobertura y límites de comparación con Salud. La lectura/baseline de #18 tiene aceptación física de César; la nueva propuesta/Home requiere su propia validación de dispositivo.

Las [decisiones](../decisions/README.md) se reservan para motivos duraderos que no sean evidentes en código, Issue o PR; esta vertical no requiere un ADR.

## Objetivo principal y semana activa — #20

`GoalEngine` transforma un baseline finito positivo en propuesta: multiplicación por 1,05, redondeo a múltiplo de 100 pasos o 10 kcal. Si el redondeo no supera baseline, usa el entero inmediatamente superior al candidato. Comprueba representabilidad en Int antes de convertir; no inventa una propuesta para baseline cero o no utilizable. `WeeklyGoal` solo admite enteros positivos. El campo de ajuste es un borrador local: Cancelar conserva el origen; Aplicar vuelve a S03; aceptar lo activa. No hay edición activa, segunda métrica ni objetivo manual sin baseline.

`OnboardingModel` conserva estado explícito y tareas finitas. La etapa completed exige objetivo válido y métrica coherente con intención; preferencias dañadas recuperan S03. Persiste únicamente intención/etapa y definición de objetivo (métrica, entero), nunca baseline/progreso/fechas/HealthKit. Una instancia restaurada va a Home y consulta otra vez sin autorización automática. No hay repositorio general ni cache persistente.

D01 v1 queda concretada por #20: `ActiveWeek` usa Calendar con lunes como primer día y zona horaria local actual, lunes 00:00 hasta lunes siguiente 00:00. Los días restantes incluyen hoy por diferencia de días naturales, sin horas fijas. La primera semana no se prorratea y consulta desde lunes. Viajes recalculan límites en la zona actual, sin reconciliar histórico; cambios de hora conservan los días y pueden variar las horas del intervalo.

`HealthProgressReading` aísla solo la lectura de acumulado principal. `HealthAuthorization` usa `HKStatisticsQueryDescriptor` async one-shot con cumulativeSum, sin muestras crudas ni separación por fuentes. `sumQuantity()` ausente sigue desconocido; valor presente finito no negativo, incluido cero, permite `gap = max(0, goal - progress)`. Home mantiene loading, disponible, insuficiente y error/reintento; destaca restante y conserva precisión Double hasta presentación. Objetivo completado no oculta el acumulado real ni aumenta el objetivo. [Descriptor primario Apple](https://developer.apple.com/documentation/healthkit/hkstatisticsquerydescriptor).

La lectura se ejecuta al entrar/restaurar Home, volver a primer plano o Actualizar/Reintentar. Consultas concurrentes comparten trabajo; si cruza semana/zona, descarta intervalo anterior y consulta el vigente. Nueva semana conserva definición de objetivo y usa nuevo intervalo. Timestamp significa consulta terminada, no sincronización del Watch. No hay observer, temporizador, background, pacing ni resumen. [Guía física](../validation/weekly-goal-home.md) y tests distinguen evidencia aislada de integración real pendiente.
