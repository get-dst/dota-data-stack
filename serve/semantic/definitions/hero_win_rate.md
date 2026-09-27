---
metric: hero_win_rate
summary: Share of pro games a hero was picked in that the hero's side won; null under 20 games.
about: player_performances.win_rate
sql: CASE WHEN COUNT(player_performances.match_id) >= 20 THEN SUM(CASE WHEN player_performances.is_win THEN 1 ELSE 0 END) * 1.0 / NULLIF(COUNT(player_performances.match_id), 0) END
aliases: [hero winrate]
grain: one value per hero (or per hero per patch, per hero per period)
---

Every game in which the hero was picked counts once; the game is a win when the hero's
side won. Read it from the smallest table that holds the question: on a patch ("this
patch", "on 7.40"), hero_patch_trends.patch_win_rate, one row per hero and patch; over a
date range ("last month", "in August"), hero_daily_stats.period_win_rate; in one position
("carries", "pos 4"), hero_position_meta.position_win_rate or player_performances
filtered on position_name; for one player's heroes, player_performances.win_rate. All of
them count the same games.

A hero picked in fewer than 20 games in the window has a rate that says nothing, so the
rate is null there and such a hero cannot top a ranking (the minimum_games term); state
the game count beside every rate, and for a named hero under the floor give the games
and wins instead.
