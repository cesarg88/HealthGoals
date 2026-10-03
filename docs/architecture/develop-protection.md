# Protección de develop

Tarea: [Issue #6](https://github.com/cesarg88/HealthGoals/issues/6). Estado al 3 de octubre de 2026: **configuración preparada, no aplicada**.

## Evidencia observada

- `develop`: `cfc2c8467499fb11662d3e2f8b78a15ed8f75481`; GitHub devuelve `protected: false` y `GET /repos/cesarg88/HealthGoals/rules/branches/develop` devuelve `[]`.
- [PR #4](https://github.com/cesarg88/HealthGoals/pull/4): abierta, `merged: false`, head `95d1cd59e533f6948a61d9393c0a323aa7752808`; check `whitespace` correcto.
- [PR #5](https://github.com/cesarg88/HealthGoals/pull/5): abierta, `merged: false`, head `d60a89bbdcd143ba3b9864982d5408d5219e778b`; checks `whitespace` y `agent-kit` correctos en [run 37112105464](https://github.com/cesarg88/HealthGoals/actions/runs/37112105464). Ambos proceden de GitHub Actions, App ID `15368`.
- El workflow de `develop` solo contiene `whitespace`. No hay check-runs en su commit de merge: el workflow actual se dispara con PRs, no con pushes a develop.
- [Ruleset dev, ID 24380908](https://github.com/cesarg88/HealthGoals/rules/24380908): `enforcement: disabled`, `include: []`, reglas `deletion` y `non_fast_forward`. La lectura con permiso contents no devuelve `bypass_actors`; no permite asegurar que la lista esté vacía. `current_user_can_bypass` devuelve `never`.
- La instalación de `Cesar-IA-Agent` tiene `issues`, `actions`, `contents`, `workflows` y `pull_requests` en escritura, y `metadata` en lectura. No incluye `administration`. La solicitud de un token `administration: write` mediante el helper existente devuelve HTTP 422. No se intentó modificar el ruleset.

## Configuración propuesta

[develop-ruleset.json](develop-ruleset.json) es el cuerpo completo para actualizar el ruleset existente mediante `PUT /repos/cesarg88/HealthGoals/rulesets/24380908`.

- Destino exclusivo: `refs/heads/develop`, sin exclusiones.
- Enforcement `active`; lista de bypass explícitamente vacía, incluida la App.
- PR obligatoria; bloqueo de borrado y force push.
- Checks obligatorios `whitespace` y `agent-kit`, asociados a GitHub Actions (`15368`). Se exige rama actualizada con la base antes del merge.
- Conversaciones de revisión resueltas; invalidación de aprobaciones formales antiguas tras nuevos commits.
- Cero aprobaciones formales obligatorias; sin CODEOWNERS obligatorio ni aprobación formal del último push. Los agentes comparten identidad de bot y no pueden aprobar sus propias PRs. Se mantiene la revisión independiente documentada del SHA completo y la decisión de merge de César conforme a AGENTS.md.

**Límite:** este ruleset no automatiza la verificación del informe independiente ni restringe por identidad quién pulsa merge. La App sigue teniendo capacidad técnica de merge por PR cuando se cumplen las reglas. El control de César sigue siendo procedimental; no se añade orquestación para convertirlo en otro check. Ningún agente debe interpretar cero aprobaciones formales como permiso para autoaprobar o fusionar.

## Condiciones antes de aplicar

1. César integra #4 y #5 tras sus revisiones y checks vigentes. Este agente no realiza esos merges. Volver a consultar ambas PRs: exigir `merged: true`, `merged_at` y registrar `merge_commit_sha`; comprobar que sus commits de merge pertenecen al historial de `develop`.
2. Leer los workflows de la nueva base y verificar que generan los dos nombres de checks en una PR actualizada con `develop`, ambos con `conclusion: success` y `head_sha` igual al head actual. No activar `agent-kit` mientras solo exista en #5; actualizar las PRs antiguas con la nueva base antes de fusionarlas bajo las reglas estrictas.
3. Volver a leer el ruleset y las reglas efectivas; si han cambiado desde esta evidencia, conciliar los cambios antes de enviar el PUT. No sobrescribir trabajo administrativo ajeno.
4. Disponer de `Administration: read and write` en la instalación de la App, o que César aplique manualmente esta configuración en el ruleset existente. Los agentes nunca usan su cuenta personal como alternativa.

## Aplicación y verificación

Tras cumplir las condiciones, desde un checkout que contenga el kit integrado, usar exclusivamente el helper existente:

```sh
python3 tools/agent-github/agent_github.py api GET /repos/cesarg88/HealthGoals/pulls/4 --permission pull_requests
python3 tools/agent-github/agent_github.py api GET /repos/cesarg88/HealthGoals/pulls/5 --permission pull_requests
python3 tools/agent-github/agent_github.py api GET /repos/cesarg88/HealthGoals/rulesets/24380908 --permission administration
python3 tools/agent-github/agent_github.py api PUT /repos/cesarg88/HealthGoals/rulesets/24380908 --permission administration --body-file docs/architecture/develop-ruleset.json
python3 tools/agent-github/agent_github.py api GET /repos/cesarg88/HealthGoals/rulesets/24380908 --permission administration
python3 tools/agent-github/agent_github.py api GET /repos/cesarg88/HealthGoals/rules/branches/develop --permission contents
```

Son comandos secuenciales con comprobación de las condiciones entre lecturas y escritura; no ejecutar el bloque de forma incondicional. Mientras #5 no esté integrada, se puede leer o invocar su helper desde otro checkout sin modificar ese checkout ni copiar o reescribir el helper.

En el resultado exigir `active`, destino exacto, `bypass_actors: []`, ambas restricciones, PR obligatoria y los dos checks vinculados a `15368`. El endpoint de reglas efectivas debe incluir esas cuatro reglas procedentes del ruleset `24380908`; revisar también reglas heredadas o adicionales que puedan bloquear el flujo. No probar con force pushes ni borrados.

Guardar en la Issue la fecha, el SHA actual de develop, los merges de las dependencias, el head y resultados de CI de la PR usada para validar y las respuestas relevantes. Solo entonces marcar la protección como activa. El merge de esta documentación por sí solo no aplica el JSON ni completa la Issue.

Contrato API: [actualización de rulesets y reglas efectivas de GitHub](https://docs.github.com/en/rest/repos/rules?apiVersion=2022-11-28).
