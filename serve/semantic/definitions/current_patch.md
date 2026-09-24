---
metric: current_patch
summary: The game version in play now — the patches row with no end date.
sql: patches.is_current = TRUE
aliases: [this patch, latest patch, the patch, current meta]
---

Declared from the patches table, never inferred from match dates. A question about
"this patch" or "the current meta" filters on it. A patch changes the game, so numbers
across a patch boundary are not comparable; when a question spans one, say so.
