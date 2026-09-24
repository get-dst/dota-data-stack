---
metric: position
summary: A pro player's role in a match, 1 to 5, derived from lane and farm.
aliases: [role, pos, carry, mid, midlaner, offlane, offlaner, support, hard support, soft support, pos 1, pos 2, pos 3, pos 4, pos 5]
sql: player_performances.position
---

1 is the carry, 2 the mid, 3 the offlaner, 4 the soft support, 5 the hard support. The
number is a convention derived, not recorded: OpenDota parses the lane each player took;
mid is 2; of the two safe-laners the one with more gold per minute is 1 and the other 5; of
the two offlaners the richer is 3 and the other 4. Roaming players and unparsed lanes get
no position. Public matches carry no lane data, so positions exist for pro matches only.
