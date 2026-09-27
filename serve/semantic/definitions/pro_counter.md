---
metric: pro_counter
summary: In pro play, a hero that the asked-about hero loses to more than usual, measured on pro_draft_matchups.
about: pro_draft_matchups.pro_matchup_win_rate
sql: SUM(pro_draft_matchups.wins) * 1.0 / SUM(pro_draft_matchups.games)
aliases: [counter, counters, pro counter, counters in pro play, pro matchup, bad matchup in pro, counter in drafts]
---

Counted on pro_draft_matchups: for the hero asked about, the opponents with the lowest
pro_matchup_win_rate are its counters in pro play; the opponents with the highest are
the heroes it does well against. Pro samples are small, so rank only pairs with at least
20 games (the minimum_games term) and state the game count beside every rate.
