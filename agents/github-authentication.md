# Autenticación con GitHub

Todos los agentes usan exclusivamente la GitHub App `Cesar-IA-Agent`, con identidad `cesar-ia-agent[bot]`, para el acceso autenticado a HealthGoals y la autoría de sus commits. No está autorizado el modo personal que el helper genérico también ofrece. Los commits existentes de César se conservan cuando se publica su trabajo, sin reescribir su autoría.

## Configuración local

El helper `tools/agent-github/agent_github.py` requiere Python 3.9 o posterior, Git 2.31 o posterior y OpenSSL. Leer con `git config --local --get` estas claves; sus valores no se incluyen en archivos versionados:

- `agentkit.github.repository`: `montunolabs/HealthGoals`
- `agentkit.github.mode`: `app`
- `agentkit.github.actor`: `cesar-ia-agent[bot]`
- `agentkit.github.actorEmail`: email noreply real del bot, con su identificador numérico
- `agentkit.github.integrationBranch`: `develop`
- `agentkit.github.appId`
- `agentkit.github.clientId`
- `agentkit.github.installationId`
- `agentkit.github.pemPath`: ruta absoluta al PEM fuera de los checkouts, permisos `0600`

Antes de un commit o acceso autenticado, verificar la configuración, `user.name` y `user.email` locales iguales al actor/email configurados, `credential.helper` local vacío y `origin` exactamente `https://github.com/montunolabs/HealthGoals.git`. Confirmar rama y destino. La configuración local es compartida por el checkout principal y sus worktrees bajo `.worktrees/`; coordinar cualquier cambio para que ningún agente ejecute operaciones con valores anteriores. Un clon adicional no hereda esa configuración y requiere configurarla antes de usarlo. No copiar el PEM a ningún checkout.

## Traslado a montunolabs

El repositorio está en `montunolabs/HealthGoals`. El traslado cambia el destino y la instalación de la App; no requiere otra identidad ni una clave nueva. La instalación debe pertenecer a `montunolabs` y tener acceso a HealthGoals.

Para actualizar el checkout principal, conservar primero los cambios pendientes y coordinar el uso exclusivo. Configurar:

```sh
git remote set-url origin https://github.com/montunolabs/HealthGoals.git
git config --local agentkit.github.repository montunolabs/HealthGoals
git config --local agentkit.github.mode app
git config --local agentkit.github.integrationBranch develop
# APP_INSTALLATION_ID must be verified for montunolabs/HealthGoals.
git config --local agentkit.github.installationId "$APP_INSTALLATION_ID"
```

Obtener el ID de instalación consultando `/repos/montunolabs/HealthGoals/installation` con un JWT de la misma App, después de verificar su identidad mediante `/app`, o desde la configuración de la instalación en GitHub. No reutilizar el ID de la instalación del propietario anterior. Conservar `appId`, `clientId`, `pemPath` y autor/email del bot si la App no ha cambiado. JWT, tokens y PEM no se imprimen ni guardan en el repo.

Las claves históricas `healthgoals.githubApp.*` no son la configuración vigente: no copiarlas sobre `agentkit.github.*`, porque podrían restablecer el repositorio o la instalación anteriores. No depender de redirecciones desde la URL antigua; el helper las rechaza al enviar credenciales.

Comprobar el acceso mediante una lectura de la Issue asignada con el helper y el destino nuevo. Si falla, revisar instalación y permisos sin recurrir a credenciales alternativas. Esta actualización no concede permisos nuevos ni cambia las protecciones de ramas.

## Operaciones

Desde el checkout de la tarea:

```sh
python3 tools/agent-github/agent_github.py api GET /repos/montunolabs/HealthGoals/issues/2 --permission issues
python3 tools/agent-github/agent_github.py api POST /repos/montunolabs/HealthGoals/pulls --permission pull_requests --body-file /ruta/temporal/pr.json
python3 tools/agent-github/agent_github.py push feature/2-adopt-agent-kit --workflows
```

Los nombres y números son ejemplos: usar la Issue y rama asignadas. El JSON contiene únicamente el cuerpo de la petición, nunca credenciales. Añadir `--workflows` solo cuando el push modifica workflows.

El helper verifica App ID, slug, instalación y repositorio; genera en memoria un JWT RS256 con OpenSSL y solicita un token limitado a un repositorio y los permisos de la operación. API y Git no recurren a credenciales globales. El push usa un repositorio bare temporal aislado de la configuración del checkout, worktree, sistema y usuario. Deshabilita helpers, askpass, hooks, proxies, reescrituras de URL, redirecciones y prompts; envía la credencial explícita solo al destino HTTPS previsto. Tokens y JWT permanecen en memoria: no imprimirlos, registrarlos ni guardarlos en URLs, configuración o archivos.

El push requiere un clon completo y los objetos locales necesarios. Fija el SHA antes de autenticar y verifica ese mismo SHA en la rama remota tras el push. El helper no ejecuta hooks de push; ejecutar antes los checks del proyecto.

Permisos: `contents: write` para push, `pull_requests: write` para PRs y sus comentarios (también al usar `/issues/{numero}/comments` sobre una PR), `issues: write` para Issues y sus comentarios y `workflows: write` adicional al modificar workflows. Las consultas de Actions requieren `actions: read`; la administración de protecciones requiere permisos específicos y no queda autorizada por este helper.

La verificación de identidad ocurre antes de la petición. Al crear una Issue, PR o comentario, comprobar además su autor `cesar-ia-agent[bot]`. El campo `user` de un recurso actualizado identifica a su autor original, no necesariamente a quien lo modificó: no usarlo como prueba del actor de una actualización.

Si falta configuración, acceso o un permiso, conservar el trabajo y comunicar el bloqueo concreto. No usar login global de `gh`, Keychain, PATs, SSH ni cuentas personales o de trabajo como alternativa. Reintentar con la misma App cuando se corrija el acceso.

La identidad compartida no sustituye la revisión independiente. Un agente distinto registra su ejecución y SHA completo. Si GitHub impide al bot aprobar su propia PR, registrar el informe independiente; César conserva la aprobación humana y el merge.
