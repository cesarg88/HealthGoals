# HealthGoals

HealthGoals es una app iOS basada en HealthKit. Discovery completado; decisión: **BUILD**.

> HealthGoals utiliza la actividad reciente del usuario para ayudarle a establecer objetivos semanales sencillos y después le dice automáticamente cómo va y exactamente qué le queda para cumplirlos.

Core loop: `Intención → Baseline → Plan → Progress → Gap → Adapt`.

## Estado actual

Este repositorio contiene la base documental, las herramientas de agentes y un bootstrap nativo SwiftUI para iPhone e iPad (iOS/iPadOS 26 mínimo). La primera vertical permite elegir intención, conectar con Salud mediante autorización nativa de lectura y entrar a un S03 sin análisis todavía. [Issue #16](https://github.com/cesarg88/HealthGoals/issues/16) y [validación en iPhone](docs/validation/onboarding-healthkit.md) delimitan la entrega. El proyecto y el scheme compartido se llaman `HealthGoals`.

La definición de producto está en [one-pager.md](docs/product/one-pager.md) y el alcance inicial en [mvp-scope.md](docs/product/mvp-scope.md).

## Punto de entrada

- [AGENTS.md](AGENTS.md): instrucciones comunes para agentes de coding.
- [Producto](docs/product/README.md): alcance, requisitos y diseño.
- [Arquitectura](docs/architecture/README.md): estado y documentación técnica.
- [Decisiones](docs/decisions/README.md): registro de decisiones duraderas.
- [Workflow manual](agents/README.md): de Issue a merge y responsabilidades.

GitHub es la fuente de verdad: las Issues definen unidades de ejecución, las PRs contienen cambios y evidencia, y los documentos del repositorio conservan el contexto compartido. Las decisiones tomadas en conversaciones deben trasladarse al repositorio o a la Issue antes de depender de ellas.

## Cómo empezar

1. Leer `AGENTS.md` y los documentos vinculados en la Issue.
2. Confirmar que la Issue tiene alcance y criterios de aceptación verificables y que sus dependencias están resueltas.
3. Trabajar en una rama y checkout/worktree exclusivos siguiendo el workflow manual.

El líder técnico coordina las asignaciones y revisiones con Product, Design e Infra según las [responsabilidades y autorización de coordinación](agents/README.md#coordinación-entre-chats). César realiza o autoriza los merges. Los [roles y dos skills del kit](agents/README.md#kit-reutilizable) apoyan ese workflow manual; no hay orquestación automática ni protección de ramas configurada por estos archivos.

## Build y tests de simulador

### Validación automática en cada PR

El check `ios-build-test` sigue la estructura útil de PickOne: tests aislados de onboarding y una prueba de lanzamiento en **un iPhone 17 Pro / iOS 26.5**, análisis estático y build **Release para iOS sin signing**. No ejecuta rotación ni iPad en cada PR. `xcodebuild test` construye app y runner, sin un build Debug previo separado. Preparación, test, análisis y Release son pasos separados para observar sus tiempos. `whitespace` y `agent-kit` se conservan; no se añaden herramientas de formato/lint ni configuración específica de PickOne.

CI usa Xcode **26.6 (17F113)** en `macos-26` arm64, ruta `/Applications/Xcode_26.6.app/Contents/Developer`, checkout del head SHA explícito y un simulador exclusivo que elimina al terminar. Para reproducir los comandos tras preparar un simulador y obtener su UDID:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild test -project HealthGoals.xcodeproj -scheme HealthGoals -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -only-testing:HealthGoalsTests \
  -only-testing:HealthGoalsUITests/BootstrapTests/testLaunch \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
xcodebuild analyze -project HealthGoals.xcodeproj -scheme HealthGoals -configuration Debug \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
xcodebuild build -project HealthGoals.xcodeproj -scheme HealthGoals -configuration Release \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
```

El resultado de lanzamiento se conserva siete días bajo `ios-launch-<head SHA>`; los logs de cada paso quedan en Actions. El build Release no acredita instalación en hardware ni distribución.

### Pruebas manuales de lanzamiento y rotación

Requisitos del script: Xcode **26.6 (17F113)**, runtime **iOS 26.5**, simuladores **iPhone 17 Pro** e **iPad Pro 11-inch (M5)**, Python 3 y Bash. El nombre local de Xcode puede variar. El script comprueba versión/build y runtime; no instala herramientas.
```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -list -project HealthGoals.xcodeproj
scripts/test-ios.sh
```

El script crea simuladores exclusivos, resuelve sus UDID y ejecuta para cada uno:

```sh
# SIMULATOR_UDID y RESULT_DIR se obtienen de la preparación del script.
xcodebuild -project HealthGoals.xcodeproj -scheme HealthGoals -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -derivedDataPath "$RESULT_DIR/DerivedData" CODE_SIGNING_ALLOWED=NO build
xcodebuild -project HealthGoals.xcodeproj -scheme HealthGoals -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -derivedDataPath "$RESULT_DIR/DerivedData" -parallel-testing-enabled NO \
  -resultBundlePath "$RESULT_DIR/BootstrapTests.xcresult" CODE_SIGNING_ALLOWED=NO test
```

Cada ejecución conserva sus logs y un `.xcresult` por dispositivo en un nuevo directorio `.build/ios.*`; las fuentes no se formatean ni modifican. Los simuladores propios se apagan y eliminan al terminar, también ante errores. El workflow separado `iOS UI tests (manual)` usa exactamente `scripts/test-ios.sh`, propaga errores y publica resultados durante siete días bajo `ios-ui-results-<SHA>-<run ID>`. En Actions, seleccionar ese workflow, Run workflow y la rama a validar; el checkout usa el SHA seleccionado por GitHub. GitHub solo ofrece workflow_dispatch cuando el workflow existe en la rama predeterminada; hasta entonces, ejecutar el script local y registrar SHA, comando y resultados en la PR. No ejecutar estas pruebas automáticamente en cada PR: solicitar evidencia por entrega cuando cambie comportamiento relevante, como lanzamiento o adaptación de UI. Una compilación verde no acredita estas pruebas ni sustituye la validación física requerida por producto.

`HealthGoalsTests` comprueba selección, navegación, autorización sustituida, errores/reintento, exclusión de solicitudes y restauración segura. `BootstrapTests` comprueba lanzamiento, S01 visible y adaptación al girar, e incluye navegación/Volver sin abrir Salud. Las cuatro orientaciones están declaradas para iPhone/iPad; el test cubre portrait y ambos landscape en iPhone, y añade portrait upside down en iPad. Los iPhone con Face ID pueden impedir upside down por política del sistema. No se simula su aceptación ni se modifica esa política.

El deployment target 26.0 no equivale a haber ejecutado en 26.0: esta combinación prueba **26.5**, no el runtime mínimo. Tampoco valida multitarea/ventanas redimensionadas de iPad, dispositivo físico, HealthKit, Watch, background, widgets, distribución ni TestFlight. Inglés y español están declarados en `knownRegions` y `CFBundleLocalizations`; textos de onboarding y uso nativo de Salud están localizados. No hay selector propio; las capacidades nativas de iOS resuelven el idioma de esta entrega sin cerrar D06. César ha confirmado `com.example.HealthGoals` y el Team `Cesar Gonzalez (Personal Team)` para esta entrega. El Team se selecciona localmente en Xcode según la [guía física](docs/validation/onboarding-healthkit.md); no se ha facilitado su ID numérico ni se guardan certificados/perfiles en el repositorio. Los targets de tests usan el mismo prefijo.

Checks de infraestructura:

```sh
python3 scripts/check-agent-kit.py
python3 -m unittest discover -s tests -v
git diff --check
```

La evidencia del SHA y de cada ejecución vive en la PR de [Issue #8](https://github.com/cesarg88/HealthGoals/issues/8). El check automático conserva el nombre `ios-build-test` con el alcance reducido descrito arriba; debe observarse verde y coordinar su obligatoriedad con César. `ios-ui-tests` es manual y no se propone como requisito de cada PR. Esta entrega no cambia las protecciones.
