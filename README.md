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

El check `ios-build-test` ejecuta formato/lint de código con versiones fijadas, tests aislados de onboarding y una prueba de lanzamiento en **un iPhone 17 Pro / iOS 26.5**, análisis estático y build **Release para iOS sin signing**. No ejecuta rotación ni iPad en cada PR. `xcodebuild test` construye app y runner sin build Debug previo. Preparación, test, análisis y Release son pasos separados; CI usa las operaciones del mismo Makefile que el gate local, evitando comandos duplicados.

CI usa Xcode **26.6 (17F113)** en `macos-26` arm64, ruta `/Applications/Xcode_26.6.app/Contents/Developer`, checkout del head SHA explícito y un simulador exclusivo eliminado al terminar. El resultado de tests se conserva siete días bajo `ios-launch-<head SHA>`; los logs de cada paso quedan en Actions. Release sin firma no acredita instalación en hardware ni distribución.

### Formato, lint y gate local

```sh
make setup         # Descarga herramientas fijadas solo a .build/tools
make format        # Modifica fuentes Swift; ejecutar antes del commit
make format-check  # Falla si hay drift, sin corregirlo
make lint          # Lint estricto, sin correcciones
make verify        # Gate completo, sin modificar fuentes
```

Las configuraciones conservadoras provienen de PickOne y se adaptan a HealthGoals: `.swiftformat` y `.swiftlint.yml`, exclusiones `.build`, `.worktrees`, `artifacts`, Build y DerivedData; mensajes de HealthGoals, sin Combine ni sufijo Protocol. Se añade la regla opt-in `no_magic_numbers`; el significado de Constants y la organización en private extensions se verifican mediante revisión, sin afirmar cobertura automática de esas convenciones.

Versiones fijadas: [SwiftFormat 0.59.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.59.1) y [SwiftLint 0.65.0](https://github.com/realm/SwiftLint/releases/tag/0.65.0). `make setup` verifica SHA-256 de los ZIP oficiales y la versión de cada binario; los hashes están en `scripts/setup-quality-tools.sh`. No utiliza Homebrew, hooks, credenciales ni instalaciones globales. Si falta una herramienta o su versión no coincide, el gate falla e indica ejecutar setup. Las verificaciones no descargan ni actualizan herramientas automáticamente.

`make verify` ejecuta formato/lint sin corrección, checks del kit y helper y `git diff --check HEAD`, y crea un único simulador iPhone para `make test`, `make analyze` y `make build-release`. Comprueba Xcode 26.6, utiliza runtime 26.5, conserva `.xcresult`/logs/DerivedData en un directorio nuevo `.build/verify.*` y elimina su simulador incluso ante errores. Las fuentes y configuraciones permanecen intactas. No confundir «sin modificar fuentes» con ausencia de artefactos temporales.

Los mismos comandos pueden ejecutarse individualmente con un iPhone exclusivo ya arrancado y un directorio nuevo de resultados:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
make test SIMULATOR_UDID="$SIMULATOR_UDID" RESULT_DIR="$RESULT_DIR"
make analyze RESULT_DIR="$RESULT_DIR"
make build-release RESULT_DIR="$RESULT_DIR"
```

El filtro automático contiene `HealthGoalsTests` y `HealthGoalsUITests/BootstrapTests/testLaunch`. Para cambios únicamente documentales, ejecutar `make repository-checks` y validar la documentación afectada, sin repetir Xcode; no reutilizar evidencia anterior tras un cambio de código/build.

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
