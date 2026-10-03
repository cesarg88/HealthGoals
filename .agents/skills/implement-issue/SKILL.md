---
name: implement-issue
description: Deliver an assigned GitHub Issue as a focused PR with reproducible acceptance evidence under the consuming project's policies.
---

Read the consuming project's instructions, authentication policy, assigned Issue, and references. Check that objective, scope, exclusions, dependencies, and acceptance are clear. Raise missing necessary decisions as concrete blockers; continue independent work where possible.

Inspect Git state and work in an exclusive checkout and task branch from the project's specified integration base. Preserve unrelated changes. Implement the authorized outcome, choosing routine technical details yourself. Update affected documentation and avoid hypothetical infrastructure.

Use the project's explicit authentication mode and identity. The kit's `tools/agent-github/agent_github.py` supports repository-scoped API requests and branch pushes; read its authentication guide before using it. Never use another account as fallback.

Run checks appropriate to the changed behavior. Open a PR linked to the Issue with acceptance evidence, executed checks, pending checks, and limitations. Verify that the remote SHA equals the delivered commit. Arrange an independent reviewer; do not review or approve your own work. After corrections, repeat relevant checks and request review of the new complete SHA. Leave merge to César or an explicitly authorized actor.
