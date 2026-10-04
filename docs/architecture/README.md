# Arquitectura

HealthGoals es una app nativa SwiftUI, Swift 6, sin dependencias externas. Deployment mínimo iOS/iPadOS 26, iPhone/iPad y orientaciones declaradas, según la [compatibilidad de producto](../product/mvp-scope.md#2-usuario-objetivo). El scheme compartido incluye app, tests de lógica y UI tests.

La [Issue #16](https://github.com/cesarg88/HealthGoals/issues/16) introduce solo S01 Intención → S02 Salud → autorización → S03 sin datos. `ActivityIntention` define walking/activity y su métrica sin depender de traducciones. `OnboardingModel` es observable y aislado al actor principal porque administra estado de interfaz. La vista usa controles SwiftUI, scroll y una columna adaptable; no hay un sistema visual propio.

`HealthAuthorizing` permite sustituir únicamente disponibilidad y solicitud en tests. `HealthAuthorization` conserva un HKHealthStore por instancia, comprueba disponibilidad en runtime y solicita lectura de pasos/energía activa sin escritura. No consulta `authorizationStatus(for:)`, histórico ni valores de Salud. Terminar la solicitud permite entrar a S03, sin conocer acceso de lectura. Durante la llamada se bloquean duplicados y navegación para evitar respuestas tardías sobre otra intención.

La persistencia usa un diccionario de UserDefaults con intención y etapa segura. S02 se guarda antes de la solicitud; la operación en curso y errores no se persisten. S03 solo se guarda después de finalizar sin error, sin flags de permiso ni datos. La restauración exige una intención válida; una etapa inválida vuelve a S01. `PrivacyInfo.xcprivacy` declara el motivo de acceso a preferencias locales de la app. No existe una capa general de persistencia.

Los mensajes están en `Localizable.xcstrings` EN/ES y la explicación nativa de lectura en `InfoPlist.strings`. Solo se habilita el entitlement HealthKit básico; no hay clinical/background, consultas, motor, objetivos ni Home. La [validación física](../validation/onboarding-healthkit.md) y el [README](../../README.md#build-y-tests-de-simulador) distinguen cobertura automática y límites.

Añadir documentación técnica cuando una tarea requiera una decisión concreta. Las [decisiones](../decisions/README.md) se reservan para motivos duraderos que no sean evidentes en código, Issue o PR; esta vertical no requiere un ADR.
