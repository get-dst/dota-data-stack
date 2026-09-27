---
metric: trend
summary: A hero's win rate over days, compared across two windows — rising, falling, or flat.
about: pub_hero_trends.daily_win_rate
sql: SUM(pub_hero_trends.wins) * 1.0 / SUM(pub_hero_trends.games)
aliases: [trending, rising, falling, going up, going down, this week vs last week, momentum]
grain: one value per hero per day
---

Read on pub_hero_trends: the daily win rate is wins divided by games for that day. A trend
is the change between two windows, for example the last seven days against the seven
before, over the same patch. Days in the sample with few games are noise; weight by games
or say the count. Never compare across a patch boundary without saying so.
