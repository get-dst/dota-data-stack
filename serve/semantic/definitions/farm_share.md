---
metric: farm_share
summary: A player's share of the side's gold earned at minute 10 (and 20) — how much of the team's farm goes to that player or position.
about: hero_playstyle.farm_share_10
sql: SUM(hero_playstyle.farm_share_10_total) / SUM(hero_playstyle.farm_games_10)
aliases: [farm priority, farm share, share of farm, share of gold, share of the team's gold, gold share, resources, who farms, farming priority, networth rank]
---

Gold here is gold earned since the horn from OpenDota's per-minute curve; the starting gold
is left out. Farm share at 10 is the player's gold at minute 10 over the five players' total
on the side; the five shares of a side sum to 1. At 20 the same, null in games that ended
before minute 20. farm_rank_10 ranks the side by gold at 10 and networth_rank by net worth
at game end (1 = richest). A position's farm priority is its average farm share — a
position 1 near a third of the side's gold, a position 5 near a tenth — read on
hero_playstyle grouped by position.
