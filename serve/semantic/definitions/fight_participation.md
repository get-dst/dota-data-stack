---
metric: fight_participation
summary: The share of a match's teamfights (as OpenDota's parser finds them) in which the player damaged or healed a hero, died, or got a kill inside the fight window.
about: hero_playstyle.fight_participation
sql: SUM(hero_playstyle.fights_present) * 1.0 / SUM(hero_playstyle.match_fights)
aliases: [teamfight participation, fight participation, fights, teamfights, joins fights, shows up to fights, fight presence, fighting hero]
---

OpenDota's parser marks a teamfight where several heroes die close together, with a start
and an end. A player is present in a fight when, inside that window, they dealt damage to a
hero, healed a hero, died, or killed a hero. The window is the parser's, so a global spell
or a fight on another lane in the same seconds also counts: presence is generous, and in pro
play most players are present in most fights. Differences between heroes are therefore
small and meaningful only with the games beside them.

This is not OpenDota's own teamfight participation (kills plus assists over the team's
kills), which this layer does not carry. "Deaths in fights" and "deaths outside fights"
split the player's deaths by whether they fell inside a fight window; deaths outside are
pick-offs, ganks and deaths to creeps or towers. The gold and XP of fights are what the
player gained over the windows, passive income included.
