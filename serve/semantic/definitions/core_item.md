---
metric: core_item
summary: A hero's core items are the first three major items finished in a game, in order; "first item" means item_order = 'first' (item_slot 1) on hero_core_items.
aliases: [core build, core items, build order, item order, first item, second item, third item, first major item, rush item]
about: hero_core_items.item_slot
sql: hero_core_items.item_slot <= 3
---

Read from hero_core_items. Within one pro game, the hero's major items are ordered by the
minute each was first completed; the first three are its core. "What do pros finish first
on X" is item_order = 'first' ranked by games; "X's core build" is the most-played item in each
of slots 1, 2 and 3, reported per slot with its game count. The three slots are counted
separately, so the most common item in slot 2 need not follow the most common item in
slot 1 in the same games. Games with fewer than three major items fill only the slots they
reach.
