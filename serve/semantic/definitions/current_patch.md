---
metric: current_patch
summary: The game version in play now — the patches row with no end date.
sql: patches.is_current = TRUE
aliases: [this patch, latest patch, the patch, current meta, right now, currently, at the moment, these days, nowadays]
---

Declared from the patches table, never inferred from match dates. A question about
"this patch", "the current meta", "right now", "currently" or "at the moment" filters on
it; so does "since the previous patch", which compares the current patch with the one
before it. A patch changes the game, so numbers across a patch boundary are not
comparable; when a question spans one, say so. A question that names no patch and no
period covers the whole loaded window, which spans several patches.
