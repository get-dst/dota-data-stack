---
metric: playstyle_position
summary: A player's role in a match, 1 to 5, on the playstyle entities — 1 carry, 2 mid, 3 offlane, 4 soft support, 5 hard support; a question about carries, mids, offlaners or supports filters on it.
about: hero_playstyle.position_name
value_aliases: {offlaner: offlane, midlaner: mid, mid player: mid, pos 1: carry, pos 2: mid, pos 3: offlane, pos 4: soft support, pos 5: hard support, position 1: carry, position 2: mid, position 3: offlane, position 4: soft support, position 5: hard support}
aliases: [role, pos, carry, carries, mid, mids, midlaner, midlaners, mid players, offlane, offlaner, offlaners, support, supports, hard support, hard supports, soft support, soft supports, pos 1, pos 2, pos 3, pos 4, pos 5, position 1, position 2, position 3, position 4, position 5]
---

1 is the carry, 2 the mid, 3 the offlaner, 4 the soft support, 5 the hard support. The
number is derived, not recorded: OpenDota parses the lane each player took; mid is 2; of
the two safe-laners the one with more gold per minute is 1 and the other 5; of the two
offlaners the richer is 3 and the other 4; on equal gold per minute the one with more last
hits, then the lower player slot, takes the lower number. Roaming players and unparsed
lanes get no position and are not in hero_playstyle.

"Which carries", "which offlaners", "hard supports" and the like are a filter, never a
grouping: `position_name` holds the word — carry, mid, offlane, soft support, hard
support — beside the number in `position`. On player_playstyle the columns are
`main_position` and `main_position_name`, the position the player played most on the
patch. The same numbers are on player_performances as `position` for questions outside
this lens.
