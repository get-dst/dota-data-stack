---
metric: synergy
summary: A hero the asked-about hero wins more with on the same side, measured over the public sample.
about: pub_duos.duo_win_rate
sql: SUM(pub_duos.wins) * 1.0 / SUM(pub_duos.games)
aliases: [synergies, pairs well with, good with, combo, lane partner, duo]
grain: one value per hero pair, over a patch
---

Counted on pub_duos: for the hero asked about, the allies with the highest duo win rate
are its best partners. Always read the game count next to the rate. Ranked All Pick only,
and a sample, not every game.
