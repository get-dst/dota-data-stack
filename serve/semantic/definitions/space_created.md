---
metric: space_created
summary: A declared proxy for "space", in two separate parts — damage absorbed from enemy heroes per game minute, and the share of the hero's deaths the side traded for a tower or Roshan within 60 seconds. No combined score.
about: hero_playstyle.damage_absorbed_per_min
sql: SUM(hero_playstyle.enemy_hero_damage_taken) * 1.0 / SUM(hero_playstyle.game_minutes)
aliases: [space, create space, creates space, creating space, space maker, space creator, making space, makes space, draws attention, absorbs attention, attention absorbed, damage absorbed, trade deaths, traded deaths, trading deaths, sacrifice]
---

"Space" in Dota is what one hero's pressure lets the rest of the team do elsewhere. The
match record cannot see pressure or intent, so this is a proxy, stated as one, in two
parts that are never added together:

1. **Attention absorbed** (`damage_absorbed_per_min`): damage the hero took from the five
   enemy heroes, per game minute. Only damage keyed to an enemy hero counts; self-damage
   (Centaur's Double Edge), creeps, towers, Roshan, illusions and summons do not. It is per
   game minute, not per minute alive, because deaths to creeps or towers carry no time.
   High for heroes the enemy chooses to hit — offlaners, initiators, tanky cores.
2. **Traded deaths** (`trade_death_share`): of the hero's deaths to an enemy hero (timed
   from the killer's kills log), the share after which the hero's side took an enemy tower
   or killed Roshan within 60 seconds. Coincidence is counted too: the tower may have
   fallen for reasons unrelated to the death.

Read from hero_playstyle for heroes and positions, player_playstyle for named players, and
space_per_match for a team, league, date or one match. Answer "who creates the most space" with attention absorbed and
name it as such, give traded deaths beside it when asked, and say that it is a proxy.
Rankings keep only rows with at least 10 games. Not measured: the farm allies gained while
the hero drew attention (the per-minute gold curve cannot separate it from kill gold in the
same fight), map pressure without damage (a hero the enemy watches but never hits), smoke
movements, and intent.
