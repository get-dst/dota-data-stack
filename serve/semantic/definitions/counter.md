---
metric: counter
summary: A hero that the asked-about hero loses to more than usual, measured over the public sample.
about: pub_matchups.matchup_win_rate
sql: SUM(pub_matchups.wins) * 1.0 / SUM(pub_matchups.games)
aliases: [counters, counter pick, what beats, bad matchup, good against, strong against]
grain: one value per hero pair, over a patch
---

Counted on pub_matchups: for the hero asked about, the opponents with the lowest matchup
win rate are its counters; the opponents with the highest are the heroes it is strong
against. Always read the game count next to the rate, since a pair seen in a handful of
games proves nothing. Ranked All Pick only, and a sample, not every game.
