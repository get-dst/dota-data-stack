---
metric: first_objective
summary: First blood, the first tower and the first Roshan of a pro match, each credited to the side that took it.
about: objective_win_rates.objective_win_rate
sql: SUM(objective_win_rates.taker_wins) * 1.0 / SUM(objective_win_rates.matches)
aliases: [first blood, first tower, first roshan, first rosh, first objective, fb]
grain: one value per match
---

Read on match_objectives and objective_win_rates. First blood is the side whose hero made
the first kill, before the horn included. The first tower is the first tower to fall, and
the side credited with it is the one that did not own it, deny or not. The first Roshan is
the side that killed Roshan first; a match where Roshan never died has no first Roshan and
is left out of its win rate. "How often does the side with first X win" is
objective_win_rate on objective_win_rates, filtered to that objective and stated with
the match count.
