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

`BaselineView` conserva título y jerarquía de tarjeta de S03 aprobada en Figma, tipografía semántica y colores locales Light/Dark en Asset Catalog. Solo muestra actividad reciente; omite todas las partes de propuesta/ajuste/aceptación de objetivo. No hay design system ni rediseño de S01/S02. La presentación redondea a entero con locale, mantiene precisión interna y usa pluralización nativa del catálogo para pasos. VoiceOver combina valor/unidad; scroll y columna máxima conservan adaptación y Dynamic Type.

## Persistencia y límites

La persistencia sigue usando un diccionario UserDefaults con intención y etapa segura. S02 se guarda antes de solicitar autorización; operaciones en curso y errores no se persisten. S03 se guarda solo tras finalizar autorización sin error, sin flags de permiso. Restaurar exige una intención válida; una etapa inválida vuelve a S01. Nunca se guardan muestras, acumulados ni baseline. `PrivacyInfo.xcprivacy` declara el motivo de preferencias locales. No hay persistencia general ni cache persistente.

Textos en `Localizable.xcstrings` EN/ES y explicación nativa de lectura en `InfoPlist.strings`; entitlement HealthKit básico, sin clinical/background. No hay motor, objetivos, semana activa ni Home. La [validación de onboarding](../validation/onboarding-healthkit.md), [baseline en hardware](../validation/healthkit-baseline.md) y [README](../../README.md#build-y-tests-de-simulador) explican cobertura y límites de comparación con Salud. La consulta real sigue pendiente de aceptación física de César.

Las [decisiones](../decisions/README.md) se reservan para motivos duraderos que no sean evidentes en código, Issue o PR; esta vertical no requiere un ADR.
