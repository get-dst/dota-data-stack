---
metric: tournament_winner
summary: The team that won a league or tournament is the winner of its last match, the deciding game of the final; the team with the most wins in the standings is not necessarily it.
aliases: [tournament winner, champion, champions, won the tournament, won the league, won the event, grand final, grand finals]
grain: one value per league
---

Read it on pro_matches: within the league, the match with the latest started_at is the
last game of the final, and its winner (radiant_team_name when radiant_win is true, else
dire_team_name) won the event. league_standings counts games won over the whole event, so
the team with the most wins there can have lost the final. A league still in progress,
or one whose final falls outside the loaded window, has no winner yet; say so instead of
naming the current leader. Name the league exactly as league_name stores it.
