---
metric: pro_match
summary: A professional match in a league OpenDota rates premium or professional; leagues it rates below professional are not counted.
aliases: [professional match, pro game, tournament match]
---

Every row in pro_matches is a pro match by this definition: organised league play from
OpenDota's pro-match feed, in a league OpenDota rates premium or professional. OpenDota
also lists grind leagues that it rates below professional; their matches stay in the raw
tables and reach no professional table, so no answer counts them. There are no public
games in this warehouse to blend in. League tier (premium or professional) is a dimension
on pro_matches and team_matches, so "premium tournaments only" is a filter on it.
