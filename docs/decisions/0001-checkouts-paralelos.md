# 0001. Checkouts paralelos por agente

- Fecha: 2026-10-07
- Estado: aceptada

## Contexto y problema

La política confirmada por César el 5 de octubre de 2026 obligaba a trabajar en el checkout principal, prohibía worktrees y clones adicionales y permitía un único agente escritor; implementación y revisión se relevaban de forma secuencial. Esa regla evitaba que dos agentes pisaran el mismo árbol de trabajo, pero impedía repartir Issues entre varios agentes a la vez y obligaba al reviewer a esperar a que el implementer liberara el checkout. Al plantear un grupo de agentes con roles especializados, la restricción se convirtió en el cuello de botella.

## Decisión

César retira la política de escritor único. Cada tarea sigue teniendo su rama exclusiva creada desde `develop` actualizado y limpio, y cada agente trabaja en un checkout exclusivo: el principal o un worktree bajo `.worktrees/`, ruta ya ignorada por Git. Varios agentes pueden escribir en paralelo mientras ninguno comparta checkout con otro. El reviewer revisa el SHA publicado desde su propio checkout. La regla queda alineada con los roles del kit, que ya piden checkout dedicado para el implementer y checkout separado para el reviewer.

Responsable de aceptarla: César.

## Alternativas consideradas y consecuencias

- Mantener el escritor único: simple de vigilar, pero sin paralelismo entre Issues ni entre implementación y revisión.
- Permitir solo worktrees para revisión: cubre el handoff, pero no el reparto de Issues entre agentes.
- Permitir checkouts paralelos sin restricción: elegida. Exige que cada agente compruebe el estado de Git de su checkout y no toque los demás. Los conflictos se resuelven en Git al integrar, no bloqueando el checkout. El resto del flujo no cambia: revisión independiente, CI del head SHA y merge autorizado por César.

## Referencias

- [Issue #44](https://github.com/montunolabs/HealthGoals/issues/44).
- [AGENTS.md](../../AGENTS.md), [workflow manual](../../agents/README.md) y [README](../../README.md), actualizados en la misma PR.
- Roles del kit: [implementer](../../agents/roles/implementer.md) y [reviewer](../../agents/roles/reviewer.md).
