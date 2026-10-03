# HealthGoals

HealthGoals es una app iOS basada en HealthKit. Discovery completado; decisión: **BUILD**.

> HealthGoals utiliza la actividad reciente del usuario para ayudarle a establecer objetivos semanales sencillos y después le dice automáticamente cómo va y exactamente qué le queda para cumplirlos.

Core loop: `Intención → Baseline → Plan → Progress → Gap → Adapt`.

## Estado actual

Este repositorio contiene la base documental, las herramientas de agentes y un bootstrap nativo SwiftUI para iPhone e iPad (iOS/iPadOS 26 mínimo). La vista técnica solo muestra el nombre de la app; todavía no implementa features de producto. El proyecto y el scheme compartido se llaman `HealthGoals`.

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

Requisitos de la combinación verificada por el script: Xcode **26.6 (17F113)**, runtime **iOS 26.5**, tipos de simulador **iPhone 17 Pro** e **iPad Pro 11-inch (M5)**, Python 3 y Bash. CI usa `macos-26` arm64 y `/Applications/Xcode_26.6.app/Contents/Developer`. Localmente el nombre de la instalación puede variar; confirmar con `xcodebuild -version`. El script falla si la versión/build o el runtime no corresponden; no instala nada.

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

Cada ejecución conserva sus logs y un `.xcresult` por dispositivo en un nuevo directorio `.build/ios.*`; las fuentes no se formatean ni modifican. Los simuladores propios se apagan y eliminan al terminar, también ante errores. CI usa exactamente `scripts/test-ios.sh`, propaga errores y publica los resultados durante siete días bajo `ios-results-<head SHA>`.

`BootstrapTests` comprueba lanzamiento, vista raíz visible y adaptación al girar en ambos dispositivos. Las cuatro orientaciones están declaradas para iPhone/iPad; el test cubre portrait y ambos landscape en iPhone, y añade portrait upside down en iPad. Los iPhone con Face ID pueden impedir upside down por política del sistema. No se simula su aceptación ni se modifica esa política.

El deployment target 26.0 no equivale a haber ejecutado en 26.0: esta combinación prueba **26.5**, no el runtime mínimo. Tampoco valida multitarea/ventanas redimensionadas de iPad, dispositivo físico, HealthKit, Watch, background, widgets, distribución ni TestFlight. Inglés y español están declarados en `knownRegions` y `CFBundleLocalizations`; la vista técnica usa solo `HealthGoals`, sin copy artificial ni selector. Seguir el idioma del sistema para las futuras pantallas es una propuesta pendiente de Product, no una decisión de comportamiento implementada. Bundle IDs `com.example.HealthGoals` y `com.example.HealthGoalsUITests` son provisionales de bootstrap, sin Team ni certificados; deben resolverse antes de signing.

Checks de infraestructura:

```sh
python3 scripts/check-agent-kit.py
python3 -m unittest discover -s tests -v
git diff --check
```

La evidencia del SHA y de cada ejecución vive en la PR de [Issue #8](https://github.com/cesarg88/HealthGoals/issues/8). El nuevo check `ios-build-test` se añadirá a las reglas obligatorias solo tras observarlo verde y coordinarlo con César; esta entrega no cambia las protecciones.
