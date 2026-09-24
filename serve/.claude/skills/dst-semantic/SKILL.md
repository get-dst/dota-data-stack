---
name: dst-semantic
description: Use when asked to author, extend, or fix this project's semantic
  layer from a connected warehouse - turns dst introspect output into
  semantic/ entities and definitions plus lens selections, then applies and
  verifies.
---

# Author the semantic layer from a warehouse

1. Get the raw material (schema + profile facts, agent-legible):

   dst introspect --connection <name> --profile > context.txt

   This is step 1 for a reason and it needs NO prior apply - it reads the
   connection straight out of dst.yaml. Every non-system schema is
   searched and names come back qualified (game.player); scope the scan
   with `datasets: [finance_marts, product_marts]` (or singular
   `schema: <name>`) under the connection's config, or the listing with
   --tables a,b. SCOPE WIDE WAREHOUSES: unscoped, introspection and
   `dst probe` span every non-system dataset, and a large unrelated dataset
   can eat the whole catalog budget (the semantic layer's own tables are
   always backfilled into the probe, but everything else you care about
   competes for the cap). Empty output is an error with the schemas it searched, never
   a blank line. `--profile` samples the warehouse right there for the facts
   the schema alone cannot give you: enum values, null rates, ranges. The
   reads are row-capped and read-only, but it is one pass per table in scope -
   on a wide warehouse pass --tables. Without it the listing is schema only
   and says NOT PROFILED at the top - it never passes a bare schema off as
   complete.
   In a warehouse whose status column holds 'A'/'C'/'X', those codes ARE the
   business knowledge; author definitions/dimensions from them.
   Table and column DESCRIPTIONS ride the listing too (the ` - <text>`
   suffixes) - the data team's own words, so mine them for definitions and
   dimensions. Do not copy them verbatim into YAML: a blank description
   falls back to the warehouse comment at serve time, so author only what
   the comment does not already say.
   One column per line as `- <name>: <type> (<warehouse type>)`; add --json
   if you would rather parse than read.

   Then RECORD those facts for the project, not just this terminal:

   dst probe

   writes profiles/<conn>.probe.json - the same passes plus partitions and
   freshness, crossed with the entities that read each table. Commit it: the
   next `dst apply` lands it in the serving prompt, so generation filters
   on literals the warehouse actually holds ('FI') instead of guessing
   formats ('Finland'). Re-run it whenever the warehouse moves - a nightly
   cron is the intended cadence. Sampling covers the tables the layer reads
   (everything while the layer is still empty); on a wide warehouse that
   default is the cheap form - `--sample-all` or `--tables a,b` widen or pin
   it, and the catalog pass records every table either way.
   The dictionaries do double duty at serve time: a filter literal outside a
   complete dictionary is repaired before execution, and a zero-row result
   probes the filtered column once before serving - so a stale artifact is
   not just a stale prompt, it weakens a guard. Keep the cron honest.

1b. When a profile fact is not enough - "is a refund a negative amount or a
   row with status='refunded'?" - look at the rows:

   dst sql "SELECT order_id, status, amount FROM orders" --connection <name> --limit 5

   SELECT-only, row-capped, and logged to the audit trail, so the probe behind
   a business rule is evidence rather than a private detour. Use it for rows,
   cross-column facts, join checks and the reconciliations that prove trap
   claims (the dst-context skill holds that standard); --profile already gives
   per-column enum values, null rates and ranges in one pass, so do not
   re-derive those here.
   Do NOT open the warehouse client yourself - dst holds that credential
   so you do not have to, and SQL run around it is ungoverned and unlogged.
   (This verb runs server-side, so the connection must be applied; introspect
   reads dst.yaml directly and works before the first apply.)

2. Author from it - file shapes are documented in semantic/README.md:
   - semantic/entities/<entity>.yaml - one per business object: grain, source
     (connection + table), fields, dimensions, metrics (type simple | ratio |
     derived, filters, format, default_time_field). Column-qualify
     every expression (entity.column, never a bare column) - the validator
     rejects ambiguity late, at apply. `fields[].type` is a closed SEMANTIC
     enum (string | number | integer | boolean | timestamp | date | json),
     never the warehouse type - copy the type introspect prints, and leave
     the parenthesised warehouse type behind.
   - semantic/relationships/<left>__<right>.yaml - one per join pair:
     left (the FK side), right, "on":, type, and a declared relationship
     (cardinality). A join described in definition prose is a smell: the
     compiler cannot enforce it and every query re-derives it. One file per
     pair - declaring the same two entities twice is an apply error.
   - semantic/definitions/<term>.md - what business words mean. Bind meaning
     to structure with about: <entity>.<member>, and make it ENFORCEABLE
     with `sql: <expression>` in the frontmatter (alias sql_expr) - without
     it the definition is prose-only and the definition_applied check can
     never verify an answer against it. A genuinely contested term
     gets status: ambiguous + possible_mappings, so dst asks the user
     which meaning is intended instead of guessing. Write definitions in
     DECISIVE form - the dst-context skill holds the authoring rules
     (exact bindings, traps in negative form, value shapes).

3. Select into a lens - nothing flows automatically, selection is curation:
   lenses/<name>/lens.yaml, under select.entities (bare name = the whole
   entity; add metrics: [..] to subset) and select.definitions (explicit
   list; new terms must be added here).

4. Land it:

   dst plan     # summary + counts (--full for per-file diffs); names stale lenses
   dst apply    # upsert + recompile; read the report's errors/warnings

   plan validates what apply validates and exits 1 if any file would be
   rejected - check the exit code, not just the diffs.

   Apply probes warehouse credentials before accepting them - a dead key
   never replaces a working one; the error names the env ref to fix.

5. Verify with one real question per new metric/term:

   dst query <lens> "the question"

   Check the answer, the sql line, and definition_used. For anything
   load-bearing, ask 2-3 times: generated SQL wobbles run to run, and a
   single rep reads as certainty when it is a coin flip.

Gotchas: a metric filter must sit on the exact metric the question uses
(avg_clv vs total_clv); entities say what exists and how it computes,
definitions say what words mean; enforceable SQL belongs on entities.
