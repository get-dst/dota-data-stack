---
metric: player_minimum_games
summary: A player's playstyle row counts in a ranking only with at least 10 games on the patch.
sql: player_playstyle.games >= 10
aliases: [which player, which players, which pro, which pros, best player, top player, player ranking]
---

The player twin of playstyle_minimum_games: rankings of named pro players by any rate on
player_playstyle keep only rows with games >= 10, and state the games beside every rate. A
question about one named player is answered whatever the count, with the count stated.
