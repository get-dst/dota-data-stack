---
metric: team_win_rate
summary: Share of a team's pro matches that the team won, counted on the team grain; null under 20 matches.
sql: CASE WHEN COUNT(team_matches.match_id) >= 20 THEN SUM(CASE WHEN team_matches.is_win THEN 1 ELSE 0 END) * 1.0 / NULLIF(COUNT(team_matches.match_id), 0) END
aliases: [team winrate, team record, team results, how did a team do]
grain: one value per team, over a period, a patch or a league
---

Counted over team_matches grouped by team_name: one row per team per match, so the
count of rows is the team's matches and the ratio is its match win rate. Never count a
team's matches on player_performances: it has five rows per side, and the count comes
out five times too high. A team with fewer than 20 matches in the window has a rate
that says nothing, so the rate is null there and such a team cannot top a ranking;
state the match count beside every rate, and for a named team under the floor give the
matches and wins instead.
