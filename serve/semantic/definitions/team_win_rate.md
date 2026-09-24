---
metric: team_win_rate
summary: Share of a team's pro matches that the team won.
sql: SUM(CASE WHEN player_performances.is_win THEN 1 ELSE 0 END) * 1.0 / COUNT(*)
aliases: [team winrate]
grain: one value per team, over a period or a patch
---

Counted over player_performances grouped by team_name: each of a team's matches
contributes five rows with the same outcome, so the ratio is the team's match win rate.
A team with few matches in the window has a rate that says little; state the match
count next to it when it is under 10.
