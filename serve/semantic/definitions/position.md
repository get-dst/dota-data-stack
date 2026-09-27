---
metric: position
summary: A pro player's role in a match, 1 to 5, derived from lane and farm — 1 carry, 2 mid, 3 offlane, 4 soft support, 5 hard support; a question about carries, mids, offlaners or supports filters on it.
about: player_performances.position_name
value_aliases: {offlaner: offlane, midlaner: mid, mid player: mid, pos 1: carry, pos 2: mid, pos 3: offlane, pos 4: soft support, pos 5: hard support, position 1: carry, position 2: mid, position 3: offlane, position 4: soft support, position 5: hard support}
aliases: [role, pos, carry, carries, mid, midlaner, midlaners, offlane, offlaner, offlaners, support, supports, hard support, soft support, pos 1, pos 2, pos 3, pos 4, pos 5]
---

1 is the carry, 2 the mid, 3 the offlaner, 4 the soft support, 5 the hard support. The
number is a convention derived, not recorded: OpenDota parses the lane each player took;
mid is 2; of the two safe-laners the one with more gold per minute is 1 and the other 5; of
the two offlaners the richer is 3 and the other 4; on equal gold per minute the one with more
last hits, then the lower player slot, takes the lower number. Roaming players and unparsed
lanes get no position.

"Which carries", "offlaners", "pos 4" and the like are a filter, never a grouping. On
player_performances `position_name` holds the word (carry, mid, offlane, soft support,
hard support) beside the number in `position`. hero_position_meta carries the number only,
so a role there is `position` = 1 to 5 by the list above. Public matches carry no lane
data, so positions exist for pro matches only.
