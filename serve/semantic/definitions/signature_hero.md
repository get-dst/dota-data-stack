---
metric: signature_hero
summary: A hero a team plays far more often than pro teams in general do, over at least 5 of its matches on the patch.
sql: team_signature_heroes.games >= 5 AND team_signature_heroes.pick_rate_lift > 0
aliases: [signature heroes, signature pick, comfort pick, pocket pick, go-to hero, team favourite]
---

Counted on team_signature_heroes: among the heroes a team played at least 5 times on the
patch, its signature heroes are those with the highest pick_rate_lift — the team's pick
rate for the hero minus the share of all pro matches that had the hero. A hero every team
plays is popular, not a signature. "Most played" is different: that ranks by games alone.
State the games and the team's match count beside the lift.
