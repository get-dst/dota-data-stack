---
metric: lane_outcome
summary: A lane is won when the side's laners are on average more than 400 gold ahead of the enemy laners in the same map lane at minute 10, lost when 400 behind, drawn in between.
about: hero_playstyle.lane_win_rate
sql: SUM(hero_playstyle.lanes_won) * 1.0 / SUM(hero_playstyle.lane_games)
aliases: [lane win, won lane, lost lane, win the lane, wins the lane, win their lane, lane win rate, laning, laning phase, lane result, lane outcome, laning stage]
---

Laners are matched by map lane (lane 1 bottom, 2 middle, 3 top), so Radiant's safe lane
meets Dire's off lane, never by lane role. Each side's laners are averaged, so a 2v1 lane
compares heroes to heroes; the result belongs to the side, and both laners share it. Gold
is gold earned by minute 10. Jungle and unparsed lanes, and lanes with no enemy hero, have
no result. Lane win rate is lanes won over lanes with a result; a drawn lane is neither.

The 400-gold band: at minute 10 a laner has earned about 3,000 gold, so 400 is roughly an
eighth of it — one kill bounty, or two creep waves of last hits. Two even lanes trade that
much back and forth, so a smaller gap is a draw; a bigger one is a lane one side is losing.
The line is declared, not derived from the data.

A lane is decided by more than gold at 10 (experience, a hero's level spike, what the
jungle did), so the result is a declared line, not a verdict.
