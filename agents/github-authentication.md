# Autenticación con GitHub

Todos los agentes usan la GitHub App `Cesar-IA-Agent`, con identidad `cesar-ia-agent[bot]`, para el acceso autenticado a HealthGoals y la autoría de commits. Se sigue el mismo mecanismo de instalación de App utilizado en PickOne.

## Configuración local

Leer con `git config --local --get` estas claves; sus valores no se incluyen en archivos versionados:

- `healthgoals.githubApp.appId`
- `healthgoals.githubApp.clientId`
- `healthgoals.githubApp.installationId`
- `healthgoals.githubApp.pemPath`
- `healthgoals.githubApp.actor`
- `healthgoals.githubApp.actorEmail`
- `healthgoals.githubApp.repository`

Antes de un commit o acceso autenticado, verificar que la configuración está completa, el actor es `cesar-ia-agent[bot]`, `user.name` y `user.email` locales coinciden con el actor configurado, `credential.helper` local está vacío y `origin` es `https://github.com/cesarg88/HealthGoals.git`. Confirmar también rama y destino de la operación. La clave PEM debe existir fuera del repositorio y tener permisos `0600`.

Los worktrees del mismo repositorio comparten normalmente esta configuración local. Los clones independientes necesitan configurarla en su propio entorno; no deben asumir que disponen de ella ni copiar la clave privada al checkout.

## Acceso

1. Generar en memoria un JWT RS256 con el Client ID y el PEM configurados: `iat` unos 60 segundos atrás y `exp` como máximo 10 minutos en el futuro.
2. Verificar la identidad de la App y resolver o verificar su instalación para `cesarg88/HealthGoals`.
3. Solicitar un token de instalación limitado al repositorio `HealthGoals` y comprobar los permisos requeridos por la operación.
4. Para Git, usar HTTPS con usuario `x-access-token` y el token como contraseña mediante una cabecera de autorización transitoria. Para Issues, PRs y otras operaciones, usar la API con ese token.
5. Mantener JWT y token únicamente en memoria del proceso. No imprimirlos ni guardarlos en URLs, configuración Git, archivos, historial, logs o contenido de Issues/PRs. No mostrar el PEM ni cabeceras de autorización.
6. Tras un push, verificar el SHA remoto. Tras una escritura de API que devuelva un actor, comprobar que sea `cesar-ia-agent[bot]`; detener nuevas escrituras si no coincide.

Permisos según la operación: `contents: write` para push, `pull_requests: write` para PRs, `issues: write` para crear o actualizar Issues y `workflows: write` para modificar workflows. Consultar también los permisos necesarios para leer o administrar Actions cuando la tarea lo requiera.

Si falta configuración, acceso o un permiso, conservar el trabajo y comunicar el bloqueo concreto. No usar el login global de `gh`, credenciales de Keychain, PATs, SSH ni cuentas personales o de trabajo como alternativa. Renovar el token y reintentar como App cuando se corrija el acceso.

La identidad compartida no sustituye la revisión independiente: un agente distinto revisa el trabajo y registra su identidad de ejecución y el SHA. Si GitHub no permite que el bot apruebe una PR creada por él mismo, registrar el informe de revisión independiente y dejar a César la aprobación humana y el control de merge.
