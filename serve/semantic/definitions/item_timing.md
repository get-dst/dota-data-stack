---
metric: item_timing
summary: The minute pros typically first buy an item on a hero — the average first-purchase minute over their games on the patch.
about: item_timings.typical_minute
aliases: [timing, when to buy, when do pros buy, rush, item rush, power spike timing]
sql: SUM(item_timings.avg_first_bought_min * item_timings.games_bought) / SUM(item_timings.games_bought)
grain: one value per hero and item, over a patch
---

Measured on item_timings from the purchase log of professional matches: for each game
where the hero bought the item, the minute of the first purchase; the timing is the
average of those minutes, weighted by games when several patches are read together
(typical_minute), never the plain average of each patch's average. Items under 1 000 gold
are not tracked. "Rush" means the item with the earliest typical minute among the hero's
expensive items. Report the game count beside the minute, since a timing over two games
is an anecdote.
