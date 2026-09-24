---
name: dst-certify
description: Use when asked to import verified BI queries (Looker/Metabase/
  Tableau exports, or plain SQL files) as certified answers, or to bootstrap
  this project's certified layer - turns dashboard tiles into
  certified_answers.yaml entries with provenance, then applies and verifies.
---

# Import verified BI queries as certified answers

1. Locate the export: LookML files, Metabase cards JSON, Tableau workbook
   XML, or plain .sql files. Only queries a human already vouches for
   qualify - scratch queries are not certified answers.

2. For each verified query, one entry in
   lenses/<lens>/certified_answers.yaml:
   - question: rephrase the tile/report title as the question a human
     actually asks ("MRR by segment" -> "what is monthly recurring revenue
     by customer segment?").
   - sql: verbatim from the export, except dialect fixes for the lens's
     warehouse. Never "improve" the query - verification covered THAT sql.
   - source: where it came from, convention "<tool>:<ref> '<title>'"
     (e.g. looker:dashboards/42 'MRR by segment').
   - verified_by: the dashboard/team/person that vouches (a person, "exec
     KPI dashboard", a ticket).

3. Parameterized tiles: author ONE template covering the family instead of
   freezing the default. The question and sql carry {slot} placeholders,
   `slots` types each one, and `sample_bindings` (required, non-empty) make
   it testable - the FIRST binding is the tile's default parameterization
   (it becomes the match anchor and the eval witness):

       - question: revenue in {period}
         sql: >
           SELECT SUM(amount_eur) FROM orders
           WHERE closed_at >= {period.start} AND closed_at < {period.end}
         slots:
           period: {type: date_range}
         sample_bindings:
           - {period: 2026-Q2}

   Slot types: date_range ({name.start}/{name.end} in SQL, half-open;
   values YYYY | YYYY-Qn | YYYY-MM | YYYY-MM-DD/YYYY-MM-DD), date, number,
   enum (inline `values` list, required). Parameterize ONLY what the tile's
   own parameters vary - never widen the approved shape. Phrase the question
   so it reads naturally for EVERY sample value ("with more than {n} orders"
   reads fine at 5 but clunky at 1 - the rendered question is what the eval
   suite asks). A tile whose parameterization you cannot express in these
   types: import the default as a frozen pair, or skip it honestly.

4. Land it:

   dst plan
   dst apply

   Apply gates reject unparseable SQL and any answer referencing tables
   outside the lens's model - the safety net; read the errors, fix the
   entry, re-apply. Optionally `dst apply --probe-certified` executes
   each new answer once and records its verified value.

5. After a bulk import, run the lens's evals / `dst reviews` before
   trusting router matches.

## The other source: the lens's OWN verified answers

BI exports are not the only feedstock. When a generated answer has been
verified correct (execution-graded, human-checked, or oracle-matched), that
answer's SQL is certifiable TODAY - source: the request id, verified_by:
whoever or whatever verified it. Certifying turns a question that was a
coin-flip into a fixed answer served without generation, and it lifts the
UNCERTIFIED neighbors too: nearby questions start serving with certified
exemplars injected (the assisted tier). Certify EARLY, as a mid-loop ratchet
after each verified win - not as a final polish. The question text does not
need to be the user's exact phrasing: matching is by meaning (embedding +
paraphrase gate), so one well-written question covers its whole family.

## Certified outranks clarify

A certified match is exempt from the ambiguity rail by design - a human
approved that exact question->SQL - so it serves verified with no
clarify round-trip. Use that deliberately for an ambiguous term's HOT
phrasings: keep `status: ambiguous` as the net, and certify a template
per decisive per-role phrasing so each audience's own wording serves its
own reading instantly:

    - question: sales attainment for {rep} in {period}
      sql: SELECT ...   # the bookings reading sales means
    - question: finance attainment for {rep} in {period}
      sql: SELECT ...   # the net-invoiced reading finance means

Phrasings you did not certify still clarify instead of guessing.

## Verify the corpus MATCHES, not just that it applied

"Applied" is not "matchable" - a corpus can be active and invisible.
After landing:

1. Read the apply output for "N certified answers have no embedding" - if it
   appears, run `dst reindex` and re-check.
2. Ask ONE certified question verbatim through the lens and check the
   response says certification=certified. If it generated instead, the
   corpus is not matching - fix before certifying more.
3. `dst test` runs generation-vs-certified for the corpus - the standing
   regression net.

The FIRST certified apply an install ever does also loads the embedding
model - it can take minutes. Use `dst apply --timeout` if needed; a
client timeout means the apply is still running and will commit (it holds
the org apply lock) - poll `dst plan` until the diff clears.

Gotchas: certified answers are served VERBATIM - they bypass generation, so
a wrong imported query is a certified wrong answer. source/verified_by are
the audit trail - always fill them. When the shared layer changes,
`dst plan` flags touching answers for re-verify. Certifying is also
writing the regression test - `dst test` runs the certified corpus.
