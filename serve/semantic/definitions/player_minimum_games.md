---
metric: player_minimum_games
summary: A player's playstyle rates are null under 10 games on the patch, so a one-game player cannot top a ranking; the games are reported beside every rate.
sql: player_playstyle.games >= 10
aliases: [which player, which players, which pro, which pros, best player, top player, player ranking]
---

The player twin of playstyle_minimum_games. Every rate metric on player_playstyle is
built with the floor inside it: null when the row's games are under 10, a value
otherwise. So a ranking of named pro players by any rate lists only players with 10 or
more games on the patch, without the reader having to ask for it, and the games are
stated beside every rate. A question about one named player under the floor gets the
count and the note that the rate is withheld for it.
