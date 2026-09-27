---
metric: first_phase
summary: The first of the three phases of a Captains Mode draft — the opening 7 bans and the first 2 picks.
about: hero_draft_stats.first_phase_ban_rate
sql: SUM(hero_draft_stats.first_phase_bans) * 1.0 / SUM(hero_draft_stats.drafted_matches)
aliases: [first phase, first ban phase, opening bans, phase one, early bans, first pick phase]
---

A Captains Mode draft on these patches has three phases, each a run of bans followed by a
run of picks: phase 1 is 7 bans then 2 picks, phase 2 is 3 bans then 6 picks, phase 3 is
4 bans then 2 picks. "First phase" or "first ban phase" means draft_phase = 1; a
first-phase ban is a ban with draft_phase = 1 (hero_draft_stats.first_phase_bans counts
them per hero). Phases are only defined for Captains Mode; pro matches played in All Pick
have none. The phase is read from the sequence, so a draft in which a ban was skipped
still has correct phases.
