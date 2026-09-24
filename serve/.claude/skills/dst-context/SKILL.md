---
name: dst-context
description: Use when writing or reviewing this project's business context -
  semantic/definitions/*.md, lens instructions, context docs. Encodes the
  authoring rules: decisive definitions with exact tables and traps raise
  accuracy; vocabulary-only prose lowers it.
---

# Write context that raises accuracy

A decisive definitions page is the single biggest accuracy lever a lens has.
A vocabulary-only glossary in the same slot gains nothing and CONVERTS safe
declines into confident wrong answers: the model stops declining, but nothing
told it which reading is right. The difference is entirely in how the context
is written.

The organizing principle: RAILS ATTACHED TO THE DATA GENERALISE ACROSS
PHRASING; RAILS ATTACHED TO THE QUESTION DO NOT. A population_filter holds for
every paraphrase and under adversarial prompting, because the compiler ANDs it
in regardless of what the question said; a declared ambiguity keyed to question
wording misses the paraphrases you did not think of. When both homes exist for
a rule, pick the data-side one.

0. The deterministic rails come FIRST - use them before writing any prose.
   On the entity:
   - population: one sentence saying who/what the rows cover; the serve
     check requires answers to carry the scope.
   - population_filter: a SQL predicate the COMPILER ANDS INTO EVERY QUERY
     against the entity - the one scope bound no phrasing can smuggle past.
     ("Active paying accounts only" as description prose is advisory;
     population_filter: "t.is_active_paying = TRUE" is enforced.)
   - pinned_dimensions: dimensions that must be pinned or GROUPed before
     any aggregate - the structural form of "never sum across currencies".
   A rule in description prose steers generation NON-deterministically -
   obeyed for one phrasing, violated for the next - and apply warns about it;
   these fields are where those rules belong.

1. Decide, don't describe. Every definition names its exact table/column and
   the computation: "Overdue = outstanding in every aging bucket except
   'Not due' (equivalently days_overdue > 0), on silver.fct_ar_aging."
   A meaning without a binding ("Aging: receivables grouped by time since
   due date") makes the model switch from robust predicates to fragile
   enumerations - the same question then answers correctly one run and
   wrongly the next.

   AND ENCODE THE BINDING, not only the prose: the frontmatter `sql:` key
   (alias `sql_expr:`) carries the enforceable expression -
   `sql: days_overdue > 0`. Without it the definition is prose-only: the
   definition_applied check SKIPS ("no enforceable definitions"), answers
   cannot be verified against the meaning, and apply warns after the fact.
   A real project authored its whole layer without it and every answer
   graded on partial evidence. Prose explains; `sql:` enforces - write both.

2. Name the trap in negative form. Write the prohibition, not the hope:
   "never a subset of buckets", "gold.rep_leaderboard excludes Renewals - do
   not use it for company-level numbers." Models drift into exactly the paths
   you don't forbid.

3. Contested terms decide or ask - never just define vocabulary. If "revenue"
   means net invoiced to finance and bookings to sales, mark the term
   status: ambiguous with possible_mappings so dst clarifies, and declare
   the per-caller rule as `audiences:` frontmatter (phrase -> the meaning it
   resolves to, e.g. `cfo: net invoiced revenue`): a question naming a
   declared audience, or exactly one mapping's own meaning, serves that
   reading - disclosed, never silent - instead of clarifying. A per-role
   rule written only in the page PROSE cannot fire: the clarify check is
   deterministic and runs before any model reads the page.
   Vocabulary alone de-inhibits: the model stops declining and guesses a
   third meaning. A wrong answer is worse than no answer.

   The clarify TRIGGER is a literal word-boundary match on the term plus its
   aliases - a phrasing containing neither is NOT caught by the rail (the
   answer then disclosing which reading it used is the floor beneath it).
   Three sub-rules, each of which costs a project real time when missed:
   - Aliases name the AMBIGUITY, not the domain. A bare "attainment" alias on
     a shared sales_attainment definition makes every question in a lens whose
     whole subject is attainment trip the clarify - and the lens answers
     nothing. Same trap as rule 10, biting through the alias field.
   - Mapping LABELS are the escape hatch: a question naming a label serves
     that reading directly. Labels must be words a user would type -
     "contracted-ARR-vs-goal" catches nothing a person types; bare
     "contracted" / "go-live" does.
   - Mapping TAILS ("meaning - entity.column") power the disclosure floor:
     name the actual column/table so a served answer can say which reading
     it used even when the clarify never fired.

4. Certify the hot metrics instead of explaining them. A certified answer is
   worth more than more prose, AND it is cheaper and faster - serving beats
   generating.

5. Small and scoped beats complete - and trim per model tier. Context rides
   EVERY query. Once decisive definitions exist, the bulky profiled-dictionary
   chunk usually stops earning its cost on a strong model - but a weaker
   fast-tier model leans on the profile's enum values and loses questions
   without it. Scope the lens to the tables the definitions name; keep the
   profile chunk for the model tiers that need it, and check by re-measuring
   your own lens rather than by assuming.

6. Document VALUE SHAPES, not just semantics. A VARCHAR column can hold JSON
   objects ({"en": "Abakan", "ru": ...}), point strings ('(lon,lat)'), or
   numbers-as-text - say so and give the access pattern (json_extract_string,
   split_part, CAST). Without the shape rule, generation compares raw JSON to
   a plain string, gets NULL, serves it as the answer and then asserts the
   data does not exist. One shape sentence prevents the whole family.

7. Verify the doc against the warehouse before landing it: every table,
   column, and enum value it names must exist verbatim (dst introspect
   --profile, which is where enum values come from).
   A definition that misnames a bucket label plants the trap it should
   remove.

   "Measured, not assumed" is a checklist, not a mood: profile first
   (introspect --profile, dst probe), RECONCILE the tables that must
   agree (dst sql), THEN write. A trap claim cites the query that proved
   it: "manager rows are team rollups - proven: each manager's booked ==
   SUM of their reps' booked - so never sum attainment across roles" is
   a rule; the same sentence without its proof query is an assumption in
   a rule's clothes.
   A reconciliation that FAILS is itself a finding to write down, never
   a probe to discard: record both numbers and the which-source-answers-
   which-question rule ("events and attribution disagree on counts by
   design; per-rep questions read attribution").

8. Pin what must not wobble. Generated SQL varies run to run even at
   temperature 0 - the same lens can grade correct on one rep and wrong on
   the next for an identical question. Definitions make answers derivable;
   only a certified answer makes them stable. Certify the questions whose
   numbers leave the company.

9. A SHARED definition's blast radius is every lens that selects it. A rule
   learned from one question family silently rewires siblings: a "render
   periods as first-day dates" convention, correct for monthly questions,
   turns every YEAR grouping in a sibling lens into a January date - right
   values, wrong grid. Scope conventions explicitly (name the carve-outs) and
   after editing a shared definition re-measure EVERY lens selecting it, not
   just the one you were fixing.

10. A rule for one question family gets its OWN term - never graft it onto a
    shared definition as a blanket rule. A "no padding" rule meant for
    growth-rate questions, written into the shared net-amount definition,
    breaks every question that needs padding. New family, new
    definitions/<term>.md, selected into the lens explicitly.

11. Definitions cannot beat the question - the question wins over the lens
    default, by design. For a question phrasing that misleads, write an
    INTERPRETATION guide ("the phrase 'only non-zero volumes are used' means
    the change is undefined when the prior day is zero - it does not mean
    scan back"), not a contradiction the model must ignore. A family that
    stays genuinely ambiguous after that is certification's job, not more
    prose.

12. Mechanics vs meaning: warehouse dialect idioms (DuckDB DATE + BIGINT
    does not bind - cast the series index) belong in lens INSTRUCTIONS;
    business meaning belongs in definitions. The serving default already
    carries the generic output contract (named quantities only, question's
    grain, full precision) - add only your domain's grain rules on top.

13. Never write REAL (or bare FLOAT) into a definition that computes a ratio.
    REAL is 4-byte single precision in DuckDB, Postgres and Snowflake, so the
    same division comes out differently: 2000/2465 is 0.8113590263691683 as
    DOUBLE and 0.8113590478897095 as REAL. A page that says "force real
    division, write CAST(... AS REAL)" forks identical questions onto the
    float32 value, so the same question answers two different numbers. To
    force non-integer division write the literal as `100.0`, or
    CAST(... AS DOUBLE); to force exactness use NUMERIC/DECIMAL. dst's
    guard widens a REAL cast to DOUBLE before serving, so a definition that
    still says REAL is not wrong on the wire - it is just misleading everyone
    who reads it, including the next model you ask to extend it.

Land changes with dst plan / apply; the certified suite and behavioral
pins are the regression net for what you wrote.
