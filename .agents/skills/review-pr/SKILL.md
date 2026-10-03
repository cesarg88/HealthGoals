---
name: review-pr
description: Independently review a GitHub PR against its Issue and current head SHA, reporting actionable findings and acceptance evidence.
---

Confirm that this execution is independent of the implementation. Read the consuming project's instructions, Issue, PR, references, and authentication policy. Use a dedicated checkout and inspect the complete PR diff at its current full head SHA.

Assess each acceptance criterion using source evidence or reproducible validation. Run checks appropriate to the change; distinguish executed, pending, and inapplicable checks. Report concrete failures with severity, file location, consequence, and supporting evidence. Do not invent requirements or expand scope.

Before publishing the review, read the remote head again. If it changed, review the new SHA; do not publish stale acceptance. Include execution identity and the full reviewed SHA in the report. Shared App identities require evidence of separate execution. If GitHub cannot accept approval from the PR author's bot account, publish the report when authorized and leave approval to César.

Every later commit requires fresh review and CI. Do not merge without César's explicit authorization. Skills do not authorize posting comments or reviews unless the user has authorized that workflow.
