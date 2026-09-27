---
metric: lane_pair
summary: Two heroes of the same side that shared a lane in a pro match, counted on lane_pairings.
about: lane_pairings.lane_pair_games
sql: SUM(lane_pairings.games)
aliases: [lane pair, laning pair, lane duo, safe lane pair, off lane pair, lane partners, laned with]
---

A lane pair is two heroes on the same side with the same lane_role: safe lane (usually
the carry, position 1, with the hard support, 5), off lane (the offlaner, 3, with the soft
support, 4), or the rarer dual mid. lane_role is relative to the side; the map lane
(bottom, top) is not, since bottom is Radiant's safe lane and Dire's off lane. Heroes on
the same team that did not lane together are not a lane pair. Pro matches only: the
public sample carries no lane data.
