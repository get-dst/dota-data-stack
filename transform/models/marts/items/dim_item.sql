-- One row per item in OpenDota's item constants, with the flags every item mart shares.
--
-- A major item is a finished item a build is planned around:
--   * it costs at least 2000 gold. Below that line the assembled items are boots
--     (Power Treads 1400, Phase Boots 1450, Arcane Boots 1500) and laning or support
--     pieces (Falcon Blade, Perseverance, Drum, Mekansm, Vanguard, Dragon Lance,
--     Mask of Madness at 1900); from 2000 up they start at Crystalys, Kaya, Sange and
--     Yasha;
--   * it is assembled from components in the constants, or it has an active ability of
--     its own (Blink Dagger, the Dagon upgrades). That keeps out the pure stat
--     components sold whole, such as Demon Edge, Hyperstone, Mystic Staff, Ultimate Orb,
--     Eaglesong, Reaver and Sacred Relic;
--   * it is not a recipe, a consumable (Moon Shard counts as one) or a neutral item.
with items as (
    select
        item_id,
        item_key,
        item_name,
        coalesce(cost, 0) as item_cost,
        quality,
        neutral_tier,
        component_count,
        has_active_ability,
        item_key like 'recipe%' as is_recipe,
        coalesce(quality, '') like 'consumable%' as is_consumable,
        neutral_tier is not null or item_key like 'enhancement%' as is_neutral
    from {{ ref('stg_items') }}
)

select
    *,
    item_cost >= 2000
    and not is_recipe
    and not is_consumable
    and not is_neutral
    and (component_count > 0 or has_active_ability) as is_major_item
from items
