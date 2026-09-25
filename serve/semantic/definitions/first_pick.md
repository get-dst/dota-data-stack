---
metric: first_pick
summary: The first hero picked in a Captains Mode draft — one per match, made by the first-pick side.
aliases: [first-pick, first picked, opening pick, first pick side, first-pick side]
---

The first pick is the match's first pick, not a team's first pick: exactly one per
drafted match. A first-pick rate is first picks of the hero divided by drafted matches
(hero_draft_stats.first_pick_rate). The first-pick side is the side that made it; its win
rate is draft_phases.first_pick_side_win_rate. A team's own first hero is
team_pick_number = 1, which for the side without the first pick is the second pick of the
match — say which is meant when a question could be read either way.
