---
metric: major_item
summary: A finished item a build is planned around — at least 2000 gold, assembled from components or with its own active ability, and not a recipe, consumable or neutral item.
aliases: [big item, core item purchase, finished item, completed item, luxury item, major items]
about: items.is_major_item
---

Decided once, in the item constants, and carried as `is_major_item` on items,
final_inventories, hero_item_builds and item_timings; hero_core_items and
item_timing_buckets hold major items only. A question about "major items" filters
`is_major_item = TRUE` on the table it reads.

The 2000-gold line: below it, the assembled items are boots (Power Treads, Phase Boots,
Arcane Boots) and laning or support pieces up to Mask of Madness and Dragon Lance at 1900;
from 2000 up they start at Crystalys, Kaya, Sange and Yasha. Blink Dagger and the Dagon
levels are major items although nothing assembles them, because they carry their own active
ability. Demon Edge, Hyperstone, Mystic Staff, Ultimate Orb, Eaglesong, Reaver and Sacred
Relic are components, never major items, whatever they cost. Moon Shard is a consumable.
An item's time is its first completion in the game; a rebuy after a sell does not move it.
