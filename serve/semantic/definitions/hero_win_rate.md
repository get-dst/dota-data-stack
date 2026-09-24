---
metric: hero_win_rate
summary: Share of pro games a hero was picked in that the hero's side won.
sql: SUM(CASE WHEN player_performances.is_win THEN 1 ELSE 0 END) * 1.0 / COUNT(*)
aliases: [hero winrate]
grain: one value per hero (or per hero per patch, per hero per period)
---

Counted over player_performances: every row where the hero was picked is one game;
the game is a win when that player's side won. A hero picked in few games has a win
rate that says little; state the game count next to it when it is under 20.
