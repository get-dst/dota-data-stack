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
with components as (
    select _dlt_parent_id, count(*) as component_count
    from {{ source('raw', 'items__components') }}
    group by 1
),

actives as (
    select distinct _dlt_parent_id
    from {{ source('raw', 'items__abilities') }}
    where type = 'active'
),

items as (
    select
        i.id as item_id,
        i.name as item_key,
        i.dname as item_name,
        coalesce(i.cost, 0) as item_cost,
        i.qual as quality,
        i.tier as neutral_tier,
        coalesce(c.component_count, 0) as component_count,
        a._dlt_parent_id is not null as has_active_ability,
        i.name like 'recipe%' as is_recipe,
        coalesce(i.qual, '') like 'consumable%' as is_consumable,
        i.tier is not null or i.name like 'enhancement%' as is_neutral
    from {{ source('raw', 'items') }} as i
    left join components as c on c._dlt_parent_id = i._dlt_id
    left join actives as a on a._dlt_parent_id = i._dlt_id
    where i.id is not null
)

select
    *,
    item_cost >= 2000
    and not is_recipe
    and not is_consumable
    and not is_neutral
    and (component_count > 0 or has_active_ability) as is_major_item
from items
