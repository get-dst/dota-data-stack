---
name: dst-warehouse-review
description: Use when asked to review a warehouse for answerability BEFORE
  building lenses on it - runs 12 shape checks over dst introspect/probe
  output and reports per-table findings, each with a rail / definition /
  remodel remedy. The failures these prevent are the ones no runtime check
  can catch.
---

# Review a warehouse for answerability

Most wrong answers that survive every verification check trace to a
TABLE-SHAPE decision, not to dst: the SQL is sound, the numbers ground, and
only the meaning is wrong. This review finds those shapes before a lens
exists. Input: `dst introspect --connection <name> --profile` output and
`profiles/<conn>.probe.json` (run `dst probe` first - value dictionaries,
row counts and partitioning are the evidence several checks read).

Report one finding per (table, shape): the shape, the evidence you computed,
the CONSEQUENCE the author would otherwise ship (say "any SUM over this
column is a multiple of the true value", not "this column is semi-additive"),
and the remedy TIER:

- rail - enforced in code, holds across phrasings (population_filter,
  pinned_dimensions, metric filters)
- definition - decisive prose plus `sql:`, which travels into generated SQL
- remodel - the shape should not reach the semantic layer at all

PROSE WILL NOT SAVE YOU: a rule in a description is obeyed for one phrasing
and violated for the next (measured three separate times). Recommending
"document this" for a shape that needs a rail is worse than no review.

## The 12 checks

1. Daily-snapshot fact table. Signal: a date column where
   distinct(PK) x distinct(dates) ~ row count. Consequence: totals grow with
   history; "now" without a MAX(date) pin reads a stale or empty day.
   Remedy: describe in `grain`; every current-state metric carries a
   `filters: [col = (SELECT MAX(col) ...)]`; consider a `_current` view.
2. Semi-additive column. Signal: a numeric column constant per
   (entity, period) across many rows. Consequence: any SUM is a multiple of
   the truth. Remedy: pinned_dimensions at minimum; PREFER remodel to one
   row per (entity, period) - the rail is coarse (it cannot check a range
   filter), the remodel removes the class.
3. Discriminator column. Signal: a low-cardinality column whose removal
   makes the PK non-unique. Consequence: multi-counting by exact multiples.
   Remedy: mandatory metric `filters` pinning one value.
4. Current-state column on a historical table. Signal: constant per entity
   across ALL dates while siblings vary. Consequence: flat or nonsense
   trends nobody questions. Remedy: never expose as a trend metric; say it
   is not point-in-time; remodel to the dimension table.
5. Dense / zero-filled grid. Signal: complete date coverage per entity AND a
   high share of zeros. Consequence: zero-vs-missing confusion both ways.
   Remedy: declare which convention holds in `grain`.
6. Scope-narrowed column name. Signal: a product/segment token its siblings
   lack (*_pms, *_emea). Consequence: a subset narrated as the company total
   (measured ~40% off, every check passing). Remedy: rename, or a decisive
   definition naming the trap in negative form + `not_computable` for the
   bare question.
7. Sentinel-dominated dimension. Signal: one literal ('(not set)', '',
   'unknown') over a large share of the value dictionary. Consequence:
   meaningless buckets; the dimension is unusable. Remedy: the dictionary
   already arms value_guard - flag it, and clean upstream.
8. Out-of-range dates. Signal: max(date) beyond today, or min far before
   the business start. Consequence: inflated unbounded totals. Remedy:
   `population_filter` bounding the column.
9. Multi-currency money. Signal: a currency-like column beside money
   columns with >1 distinct value. Consequence: a sum denominated in
   nothing. Remedy: `pinned_dimensions: [currency]`.
10. Duplicate measure across tables. Signal: same column name/semantics in
    2+ tables. Consequence: a bound declared on one is bypassed by phrasing
    that routes to the other. Remedy: declare it on EVERY exposing entity,
    or keep one canonical carrier.
11. Constant boolean. Signal: exactly one distinct value across all rows.
    Consequence: the column can answer nothing and invites a confident
    zero/total. Remedy: exclude it, or declare the question not_computable.
    (One line to check; caused a real wrong answer nothing caught.)
12. Placeholder metric. Signal: an entity metric with no `agg` and no
    `expr`. Consequence: generation improvises the ratio and gets the grain
    wrong. Remedy: fill it in or delete it. (Also one line.)

## Interactions worth flagging in the same pass

If a `current_x` metric pins MAX(date), do NOT also define `total_x` over
the SAME expression with an incompatible mandatory filter: the guard
resolves such twins by the question's wording, and a question naming
neither is rejected with the conflict spelled out. Give the second metric
its own expression or its own entity. (`dst apply` warns about the pair;
the review should catch it before the model exists.)

## Escalate rulings; never silently pick

Some findings are DECISIONS, not detections: period conventions ("last
week" = previous calendar week or trailing 7 days?), contested terms, which
of two defensible churn definitions is canonical. List them as decisions
owed by a human, with the candidate readings and how far apart the numbers
land. A ~1% error from an undeclared week convention fails no check ever -
this list is the only place it can be caught.

## Worked shape (the hostile-table pattern)

A daily grid carrying a monthly quota copied onto every row, dense-filled
per on-roster rep, stacks THREE shapes (snapshot grain + semi-additive +
dense fill). The entity's own description said "never SUM across days";
generation summed across days anyway, twice, two wrong magnitudes. The
finding to write: "remodel to one row per rep-month - no rail fully covers
this stack, and the description demonstrably does not."

Finish by proposing the semantic/ changes for every rail- and
definition-tier finding (the dst-semantic and dst-context skills hold the
authoring rules) and a remodel list for the data team, ordered by the cost
of the wrong answer each shape ships.
