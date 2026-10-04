# Validación del onboarding y autorización de Salud

[Issue #16](https://github.com/cesarg88/HealthGoals/issues/16). Esta entrega recorre S01 → S02 → solicitud nativa → S03. S03 es un destino sin lectura ni análisis; no muestra baseline, objetivos ni valores de Salud. La finalización de una solicitud no acredita autorización de lectura ni existencia de datos.

## Instalación en el iPhone de César

1. Abrir `HealthGoals.xcodeproj` desde el checkout de la PR y seleccionar el scheme `HealthGoals`.
2. En el target HealthGoals, Signing & Capabilities, seleccionar **Cesar Gonzalez (Personal Team)** y conservar el Bundle Identifier confirmado **`com.example.HealthGoals`**. El identificador ya está configurado; el Team se elige localmente en Xcode, porque no se ha facilitado su ID numérico. Los identificadores de los targets de tests usan el mismo prefijo. No guardar certificados, perfiles ni credenciales en Git.
3. Comprobar que HealthKit aparece habilitado y que el perfil de provisioning para ese App ID incluye `com.apple.developer.healthkit`. El target usa `HealthGoals/HealthGoals.entitlements`; no habilitar Clinical Health Records ni Background Delivery para esta entrega. Xcode puede generar el perfil con Automatically manage signing si el Team dispone de permisos.
4. Conectar un iPhone con iOS 26 o posterior, confiar en el Mac y activar el modo desarrollador si iOS lo solicita. Seleccionar el dispositivo como destino y ejecutar Run. Los builds de CI sin signing no se instalan directamente en el iPhone.
5. Si Xcode informa de restricciones del Team o de provisioning, resolverlas con el Team autorizado; no cambiar a otra cuenta por iniciativa del agente. Registrar el error sin credenciales ni datos personales.

## Recorrido real

1. En una instalación sin progreso guardado, comprobar «Tu actividad, a tu ritmo», ninguna opción seleccionada y Continuar deshabilitado.
2. Seleccionar Caminar más. Comprobar marca de selección además del color y Continuar habilitado.
3. Pulsar Continuar. S02 explica pasos y energía activa, acceso solo de lectura, ausencia de modificación de Salud y de envío a un backend.
4. Pulsar Volver: Caminar más sigue seleccionada. Volver a S02.
5. Pulsar Conectar con Salud. Comprobar que aparece el panel nativo de Apple con Pasos y Energía activa para lectura, sin tipos de escritura. Mientras la solicitud está en curso no se permiten otra solicitud ni Volver.
6. Finalizar el panel. Si HealthKit completa la solicitud sin error, aparece «Tu punto de partida», sin números y sin afirmar permiso concedido. Si hay un error técnico, permanece en S02, muestra el mensaje recuperable y permite Reintentar/Volver conservando intención.
7. Cerrar completamente la app y abrirla: S03 se recupera; solo significa que terminó la solicitud. No se reabre el panel automáticamente.
8. Para repetir con Moverme más, eliminar la app de prueba y reinstalar desde Xcode. Esto elimina el progreso local, pero **no garantiza** que iOS vuelva a presentar autorización: Apple puede recordar la elección de permisos. No añadir un botón de reset a producción. Ejecutar de nuevo los pasos anteriores y comprobar la selección exclusiva.
9. Repetir una solicitud limitando/denegando lectura de uno o ambos tipos cuando iOS permita mostrar el panel. También se pueden revisar/revocar permisos desde Salud o Ajustes. La app nunca dice «permiso concedido/denegado» ni confirma datos existentes. Un retorno sin panel si ya se eligieron permisos es un comportamiento válido de HealthKit.
10. Cancelar el panel si esa versión de iOS ofrece la acción. Si la API devuelve error, permanece en S02 y permite reintentar; si finaliza sin error, avanza a S03 sin inferir lectura. Registrar el comportamiento observado, sin suponer un resultado universal.
11. Interrumpir la app en S01 tras seleccionar, en S02 y, si es razonable en el dispositivo, durante la solicitud. Al abrir debe recuperar selección/etapa segura; una solicitud interrumpida queda en S02 hasta terminar una nueva llamada sin error.
12. Cambiar español/inglés usando los ajustes de idioma del sistema/app de iOS. Comprobar textos y mensaje nativo de uso de Salud. Probar un tamaño de letra grande, VoiceOver y giro horizontal: selección anunciada, textos alcanzables por scroll y controles accesibles. En iPad repetir adaptación cuando se disponga de dispositivo; no asumir disponibilidad de Salud por modelo, se comprueba en runtime.

## Límites y evidencia

Un iPhone compatible normal no permite provocar de forma determinista un error técnico o la indisponibilidad de HealthKit. No manipular entitlements, perfiles ni datos personales para inventar una prueba. Los tests con un servicio pequeño sustituido verifican indisponibilidad, error/reintento y solicitud en curso; no acreditan integración física. Registrar qué casos físicos se han observado y cuáles no fueron reproducibles. La app conserva la selección y ofrece Reintentar/Volver ante no disponibilidad, sin prometer poder habilitar Salud en un dispositivo incompatible.

La validación en iPhone real, signing, panel nativo y mensajes EN/ES quedan pendientes de César hasta que registre el resultado para el SHA de la PR. Simulador/CI no acreditan estos puntos. No adjuntar capturas con datos reales de Salud. Apple Watch, consultas históricas y baseline pertenecen a la siguiente Issue.

## Comprobación automática

Con Xcode 26.6 y un simulador iOS 26.5 propio ya arrancado:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild test -project HealthGoals.xcodeproj -scheme HealthGoals -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -only-testing:HealthGoalsTests \
  -only-testing:HealthGoalsUITests/BootstrapTests/testLaunch \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

CI ejecuta estos filtros, análisis y Release sin signing en un iPhone. La prueba manual adicional `BootstrapTests/testIntentionNavigationAndBack` comprueba selección/Volver. `scripts/test-ios.sh` conserva la suite amplia iPhone/iPad y rotación; no se incorpora esa batería a cada PR.

## Referencias primarias verificadas

- [Configuración de HealthKit](https://developer.apple.com/documentation/healthkit/setting-up-healthkit): disponibilidad runtime, entitlement y mensaje de uso de lectura.
- [Autorización](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data) y [requestAuthorization](https://developer.apple.com/documentation/healthkit/hkhealthstore/requestauthorization(toshare:read:)): finalización de solicitud, panel nativo y ausencia de permisos READ observables. El SDK 26.5 documenta que el resultado no significa acceso concedido; la variante async lanza error cuando la solicitud no termina correctamente.
- [Motivo de acceso a UserDefaults](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons): el manifiesto declara CA92.1 para preferencias solo accesibles por esta app. No se guardan valores HealthKit.

- [Capacidades admitidas por Apple](https://developer.apple.com/help/account/reference/supported-capabilities-ios): HealthKit figura disponible también con una cuenta gratuita. Comprobar el provisioning efectivo; no presuponer que el Personal Team requiera pago.
