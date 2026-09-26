---
metric: hero_win_rate
summary: Share of pro games a hero was picked in that the hero's side won; null under 20 games.
sql: CASE WHEN COUNT(player_performances.match_id) >= 20 THEN SUM(CASE WHEN player_performances.is_win THEN 1 ELSE 0 END) * 1.0 / NULLIF(COUNT(player_performances.match_id), 0) END
aliases: [hero winrate]
grain: one value per hero (or per hero per patch, per hero per period)
---

Counted over player_performances: every row where the hero was picked is one game;
the game is a win when that player's side won. A hero picked in fewer than 20 games in
the window has a rate that says nothing, so the rate is null there and such a hero
cannot top a ranking (the minimum_games term); state the game count beside every rate,
and for a named hero under the floor give the games and wins instead.
