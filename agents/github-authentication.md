# Autenticación con GitHub

Todos los agentes usan exclusivamente la GitHub App `Cesar-IA-Agent`, con identidad `cesar-ia-agent[bot]`, para el acceso autenticado a HealthGoals y la autoría de sus commits. No está autorizado el modo personal que el helper genérico también ofrece. Los commits existentes de César se conservan cuando se publica su trabajo, sin reescribir su autoría.

## Configuración local

El helper `tools/agent-github/agent_github.py` requiere Python 3.9 o posterior, Git 2.31 o posterior y OpenSSL. Leer con `git config --local --get` estas claves; sus valores no se incluyen en archivos versionados:

- `agentkit.github.repository`: `cesarg88/HealthGoals`
- `agentkit.github.mode`: `app`
- `agentkit.github.actor`: `cesar-ia-agent[bot]`
- `agentkit.github.actorEmail`: email noreply real del bot, con su identificador numérico
- `agentkit.github.integrationBranch`: `develop`
- `agentkit.github.appId`
- `agentkit.github.clientId`
- `agentkit.github.installationId`
- `agentkit.github.pemPath`: ruta absoluta al PEM fuera de los checkouts, permisos `0600`

Antes de un commit o acceso autenticado, verificar la configuración, `user.name` y `user.email` locales iguales al actor/email configurados, `credential.helper` local vacío y `origin` exactamente `https://github.com/cesarg88/HealthGoals.git`. Confirmar rama y destino. Los worktrees comparten normalmente la configuración; los clones independientes requieren su propia configuración. No copiar el PEM al checkout.

Para migrar la configuración anterior, ejecutar en un checkout de HealthGoals:

```sh
for key in repository actor actorEmail appId clientId installationId pemPath; do
  value=$(git config --local --get "healthgoals.githubApp.$key") || exit 1
  test -n "$value" || exit 1
  git config --local "agentkit.github.$key" "$value" || exit 1
done
git config --local agentkit.github.mode app
git config --local agentkit.github.integrationBranch develop
```

No imprime valores ni elimina las claves anteriores. Configurar además autor/email y origin si el clon aún no los tiene; detenerse si no corresponden al bot y repositorio previstos. La migración no concede permisos de instalación.

## Operaciones

Desde el checkout de la tarea:

```sh
python3 tools/agent-github/agent_github.py api GET /repos/cesarg88/HealthGoals/issues/2 --permission issues
python3 tools/agent-github/agent_github.py api POST /repos/cesarg88/HealthGoals/pulls --permission pull_requests --body-file /ruta/temporal/pr.json
python3 tools/agent-github/agent_github.py push feature/2-adopt-agent-kit --workflows
```

Los nombres y números son ejemplos: usar la Issue y rama asignadas. El JSON contiene únicamente el cuerpo de la petición, nunca credenciales. Añadir `--workflows` solo cuando el push modifica workflows.

El helper verifica App ID, slug, instalación y repositorio; genera en memoria un JWT RS256 con OpenSSL y solicita un token limitado a un repositorio y los permisos de la operación. API y Git no recurren a credenciales globales. El push usa un repositorio bare temporal aislado de la configuración del checkout, worktree, sistema y usuario. Deshabilita helpers, askpass, hooks, proxies, reescrituras de URL, redirecciones y prompts; envía la credencial explícita solo al destino HTTPS previsto. Tokens y JWT permanecen en memoria: no imprimirlos, registrarlos ni guardarlos en URLs, configuración o archivos.

El push requiere un clon completo y los objetos locales necesarios. Fija el SHA antes de autenticar y verifica ese mismo SHA en la rama remota tras el push. El helper no ejecuta hooks de push; ejecutar antes los checks del proyecto.

Permisos: `contents: write` para push, `pull_requests: write` para PRs y sus comentarios (también al usar `/issues/{numero}/comments` sobre una PR), `issues: write` para Issues y sus comentarios y `workflows: write` adicional al modificar workflows. Las consultas de Actions requieren `actions: read`; la administración de protecciones requiere permisos específicos y no queda autorizada por este helper.

La verificación de identidad ocurre antes de la petición. Al crear una Issue, PR o comentario, comprobar además su autor `cesar-ia-agent[bot]`. El campo `user` de un recurso actualizado identifica a su autor original, no necesariamente a quien lo modificó: no usarlo como prueba del actor de una actualización.

Si falta configuración, acceso o un permiso, conservar el trabajo y comunicar el bloqueo concreto. No usar login global de `gh`, Keychain, PATs, SSH ni cuentas personales o de trabajo como alternativa. Reintentar con la misma App cuando se corrija el acceso.

La identidad compartida no sustituye la revisión independiente. Un agente distinto registra su ejecución y SHA completo. Si GitHub impide al bot aprobar su propia PR, registrar el informe independiente; César conserva la aprobación humana y el merge.
