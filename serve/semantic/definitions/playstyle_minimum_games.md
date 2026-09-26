---
metric: playstyle_minimum_games
summary: A hero-and-position playstyle rate is null under 10 games on the patch, so a one-game row cannot top a ranking; the games are reported beside every rate.
sql: hero_playstyle.games >= 10
aliases: [best, most, highest, lowest, least, fewest, top, rank, ranking, which hero, which heroes, enough games, sample size]
---

Every rate on hero_playstyle — fight participation, farm share, lane win rate, damage
absorbed, traded deaths, wards per game — is an average over the hero's games in one
position on one patch. A hero seen once in a position has a lane win rate of 0 or 1 and
would top any ranking. The floor is built into the metrics: each rate is null when the
row's games are under 10, so a ranking over hero_playstyle lists only rows with 10 or
more games, and every rate is reported with its games.

Why 10 and not the 20 of the win-rate rule: these are per-game averages of continuous
quantities (a farm share, damage per minute), which settle faster than a win/loss coin;
and hero-position rows on one patch are thin in pro play. A question about one named hero
under the floor gets the count and the note that the rate is withheld for it.
