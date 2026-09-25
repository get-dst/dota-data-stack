---
metric: comeback
summary: A pro match the winner won after trailing by 10 000 gold or more at some minute; for the losing side the same match is a throw.
sql: match_leads.is_comeback = TRUE
aliases: [comebacks, came back, throw, throws, threw, thrown game, blown lead, lost a lead]
grain: one value per match
---

Read from the per-minute gold advantage, on match_leads. The threshold is 10 000 gold: a
side that has led by that much at some minute almost always goes on to win, so a win
from that far behind is rare. A comeback and a throw are one event seen from each side: the winner came
back, the loser threw. So "which team threw the most games" counts matches by
throw_team_name, and "which team made the most comebacks" by comeback_team_name. Matches
without a per-minute advantage are not counted either way.
