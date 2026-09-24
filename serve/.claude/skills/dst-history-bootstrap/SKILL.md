---
name: dst-history-bootstrap
description: Use when starting a dst project on a warehouse that already has
  query traffic - mines 30 days of query history into a draft semantic layer
  (entities, definitions incl. ambiguous terms where practice disagrees) and
  certified-answer candidates, then applies and verifies.
---

# Bootstrap the semantic layer from query history

The warehouse's query log is a usage-weighted map of the org's real semantic
layer: which tables carry the business, what the metrics are called, and where
practice already disagrees with itself. You (the agent) do the reading and the
judgment; dst's apply gates catch what you get wrong.

1. Pull shape-level history (metadata only - no table access needed). Save the
   result OUTSIDE the repo (query text can embed literals from your tables):

   BigQuery (needs bigquery.jobs.listAll; swap the region):

       SELECT query_info.query_hashes.normalized_literals AS shape_hash,
              ANY_VALUE(query) AS representative_text,
              COUNT(*) AS run_count,
              COUNT(DISTINCT user_email) AS principals
       FROM `region-eu`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
       WHERE job_type = 'QUERY' AND statement_type = 'SELECT'
         AND state = 'DONE' AND error_result IS NULL
         AND creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
         AND query_info.query_hashes.normalized_literals IS NOT NULL
         AND NOT STARTS_WITH(query, '/* dst:')
         AND NOT CONTAINS_SUBSTR(query, 'INFORMATION_SCHEMA')
       GROUP BY shape_hash
       HAVING COUNT(*) >= 2 OR COUNT(DISTINCT user_email) >= 2
       ORDER BY run_count DESC

   Snowflake (needs IMPORTED PRIVILEGES on the SNOWFLAKE database):

       SELECT query_parameterized_hash AS shape_hash,
              ANY_VALUE(query_text) AS representative_text,
              COUNT(*) AS run_count,
              COUNT(DISTINCT user_name) AS principals
       FROM snowflake.account_usage.query_history
       WHERE query_type = 'SELECT' AND execution_status = 'SUCCESS'
         AND start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
         AND query_text NOT LIKE '/* dst:%'
         AND query_text NOT ILIKE '%account_usage%'
       GROUP BY query_parameterized_hash
       HAVING COUNT(*) >= 2 OR COUNT(DISTINCT user_name) >= 2
       ORDER BY run_count DESC

2. Separate AUTHORED from GENERATED. Only authored SQL expresses judgment;
   generated SQL is a tool consuming metrics, not defining them. The tells:
   - dbt: leading comment {"app": "dbt", ...} - ingest via `dst import dbt`
     instead of mining.
   - BI pivot engines: __mask / rowDepth / colDepth projections, agg0_ aliases.
   - Semantic-layer compilers: __with_t_0-style generated CTEs.
   - dst itself: /* dst: ... */ (already filtered above).
   - Service-account principals running one shape on a schedule.
   Treat each generated family as ONE consumer surface however many filter
   permutations it ran.

3. Read the authored head. Group statements by metric intent - what is being
   measured (aggregate + columns) and what the author CALLED it (aliases are
   the org's own vocabulary). Usage weights tell you which tables and metrics
   carry the org; that is your entity shortlist.

4. Draft `semantic/`:
   - Entities for the load-bearing tables: grain from observed keys and joins,
     use_cases from what the queries actually do, fields the queries touch.
   - Definitions for recurring metrics, in the org's own vocabulary.
   - Where authored practice genuinely DISAGREES - same metric, different
     filters/grain/measure (e.g. turns counted per message vs per conversation)
     - write `status: ambiguous` with `possible_mappings` taken from the real
     variants. Ask, don't crown: run_count is popularity, not correctness.

5. Propose certified candidates from the most-run authored questions whose
   intent is unambiguous, into `certified_answers.yaml` with
   `source: "history:<shape_hash>"`. Leave `verified_by` for a human - never
   mark verified yourself; a certified answer is served VERBATIM, so a human
   must vouch before it counts.
   A shape cluster whose runs differ ONLY in benign literals (the period, a
   segment value) is ONE candidate, not N: author a single TEMPLATE - {slot}
   placeholders + `slots` types + `sample_bindings` (first = the most-run
   literals; see the dst-certify skill for the shape). But heed the
   gotcha below first: a literal difference that changes MEANING (a 120- vs
   180-day window definition) is a war to surface, never a slot to widen.

6. Select the drafted assets into a lens, then:

       dst plan
       dst apply --probe-certified
       dst query <lens> "<one real question per drafted metric>"

Gotchas:
- Literal-only differences can BE the war: a 120- vs 180-day window differs
  only in a literal the shape hash folded. Read the literals in the variants
  before declaring two statements equivalent.
- Scheduled traffic inflates run counts; weigh multi-principal shapes higher.
- The history export never goes into git.

This skill is the COLD start - the warehouse's history, before dst serves
anything. Once a lens has real traffic of its own, `dst evals from-traffic
<lens>` drafts suite cases from dst's request log directly (observed outcome
shape as the expectation); review them the same way as step 5's candidates.
