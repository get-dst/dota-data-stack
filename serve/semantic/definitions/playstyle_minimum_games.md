---
metric: playstyle_minimum_games
summary: A hero-and-position playstyle row counts in a ranking only with at least 10 games on it.
sql: hero_playstyle.games >= 10
aliases: [best, most, highest, lowest, least, fewest, top, rank, ranking, which hero, which heroes, enough games, sample size]
---

Every rate on hero_playstyle — fight participation, farm share, lane win rate, damage
absorbed, traded deaths, wards per game — is an average over the hero's games in one
position on one patch. A hero seen once in a position has a lane win rate of 0 or 1 and
would top any ranking. So a ranking over hero_playstyle keeps only rows with games >= 10,
and every rate is reported with its games.

Why 10 and not the 20 of the win-rate rule: these are per-game averages of continuous
quantities (a farm share, damage per minute), which settle faster than a win/loss coin;
and hero-position rows on one patch are thin in pro play. A question about one named hero
is answered whatever the count, with the count stated.
