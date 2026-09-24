---
name: dst-flywheel
description: Use when a lens answers questions wrongly and you want to
  improve it systematically - the loop: diagnose from traces, file
  corrections with an explicit target, gate the drafted patch, apply,
  re-measure everything, certify verified wins.
---

# The improvement loop

One lap = measure, diagnose, correct, gate, apply, re-measure, certify. A lens
that starts out answering half its questions is normally a handful of laps
away from answering nearly all of them; the laps are cheap, guessing is not.

1. Measure with REPEATS (2-3 per question) and keep request_ids. A single
   rep is a coin flip dressed as a verdict; per-question pass RATES are the
   signal. Grade by executing, not by eyeballing prose. Send an
   `X-Dst-Agent: benchmark` header (or any label) on measurement traffic so
   the runs are attributable in the audit trail and the governed KPI rollup
   is not permanently mixed with your own benchmarking.

2. Diagnose each miss from its trace and SQL before touching anything.
   The classes repeat: wrong VALUES (missing rule -> definition), right
   values in the wrong GRID (grain/projection -> conventions or the answer
   contract), DECLINE (guard rejection or dialect idiom -> lens
   instructions), and artifact-obedient wrongness - the model faithfully
   executing a WRONG ruling you authored. Consistent failure across reps
   means the artifact is wrong, not the model.

   AUDIT THE EXPECTATION BEFORE FIXING THE SYSTEM. A sizeable share of red
   eval cases are usually wrong TESTS, not wrong behaviour - most often
   out-of-scope questions filed against the lens that should answer them
   instead of the one that should decline. A case asserting behaviour the
   governance is right to refuse is the case's bug; fix or park it
   (status: candidate) instead of patching the lens to satisfy it.

3. File the correction through the product, with an explicit target:

   dst correct <request_id> --kind definition --target "<term>" --note-file note.md

   ALWAYS pass target (the verb requires it). Without it, placement is
   vocabulary matching and a cross-cutting note lands on the wrong shared
   definition - where it becomes a blanket rule that regresses every other
   question using that term. A target naming a NEW term drafts a new
   definition. The note is a paragraph, not a flag - write it to a file and
   pass --note-file (or `-` to pipe it in); --note takes a one-liner. Add
   --corrected-sql when you know the SQL that would have been right.

4. Gate the draft - `dst patches draft <ticket_id>` drafts it and PRINTS
   the target and body; READ them before approving: the right target, and
   the right AMENDMENT. The drafter amends - rulings the correction never
   mentioned come back whether or not the model restated them - so what you
   are checking is whether the CHANGED ruling is right, not whether the rest
   survived. Approve with `dst patches approve <id> --dir .`; a bad
   draft gets `dst patches reject <id> --note "why"` - the note is fed
   to the next draft as a hard constraint, so say what to keep and what to
   drop.

   Approve writes into the file that already authors the term, whatever it
   is named. It defaults to this lens's tree; add `--shared` when the term
   is cross-cutting and belongs in semantic/definitions/ - that reaches
   every lens selecting it, so re-measure them all (step 5).

5. `dst apply`, then re-measure the WHOLE set including questions that
   were passing - a shared-asset edit reaches every lens selecting it, and
   the regression you cause is always in the question you were not looking
   at. Re-measure sibling lenses too when the patch touched semantic/.
   The fast form: `dst evals gate <lens>` runs ONE lens's publish gate as a
   dry run (seconds, against a multi-minute apply) - run it from the project dir so
   it gates the CANDIDATE tree, unpublished shared-asset edits included
   (outside a project dir it gates the server's stored bundle and says so).
   `dst plan` names which lenses a shared edit made stale - gate each.

   `dst test` records every run, so the re-measure has a one-line verdict:
   `dst runs <lens> --diff prev latest` - score delta plus per-case flips,
   exit 1 on a regression, so a lap that traded one fix for one break can
   never read as a wash. And when the candidate fix is a CONFIG fork
   (model, temperature, instructions), measure instead of arguing:
   `dst experiment <lens> --vary model.temperature=0.0,0.7` runs the
   variants in a disposable env, side by side, and tears it down after.

6. Certify each verified win (the dst-certify skill, "own verified
   answers" section) - it pins the question against wobble, serves far
   faster (no generation), and lifts uncertified neighbors via the assisted
   tier. Then the eval gate has a corpus and future applies are guarded.

7. Residual wobble on questions whose artifacts are RIGHT (a rep drops a
   filter, forgets a carry-forward) is not an authoring problem - it is
   what certification exists for. Stop writing prose at that point.

Recovery: the lens project is a git repo. A bad patch is `git checkout` of
the file + `dst apply` - under a minute, no server surgery.
