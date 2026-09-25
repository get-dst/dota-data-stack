-- Everything a pro hero ended the game with, per patch, hero, slot group and item:
--   main         the six inventory slots
--   backpack     the three backpack slots
--   neutral      the neutral item slot (the artifact found in the jungle, tiers 1-5)
--   enchantment  the second neutral slot (Greedy, Alert, Timeless and the like)
--   consumed     buffs consumed into the hero: Aghanim's Blessing (the Scepter upgrade
--                without the item held), Aghanim's Shard, Moon Shard
-- A game counts once per slot group even when the item sits there twice. A held
-- Aghanim's Scepter shows in main or backpack; the match record's scepter flag is set
-- only for the consumed Blessing, which is why the two never overlap.
with players as (
    select
        pm.match_id,
        pm.patch_id,
        pm.patch_name,
        pm.hero_id,
        pm.hero_name,
        pm.is_win,
        pm.item_0,
        pm.item_1,
        pm.item_2,
        pm.item_3,
        pm.item_4,
        pm.item_5,
        pm.item_neutral,
        pm.has_aghanims_scepter,
        pm.has_aghanims_shard,
        inv.backpack_0,
        inv.backpack_1,
        inv.backpack_2,
        inv.item_neutral2,
        inv.has_moon_shard_buff
    from {{ ref('fact_player_match') }} as pm
    inner join {{ ref('stg_player_inventory') }} as inv
        on inv.match_id = pm.match_id and inv.player_slot = pm.player_slot
),

slots as (
    select *, 'main' as slot_group, item_0 as item_id from players
    union all select *, 'main', item_1 from players
    union all select *, 'main', item_2 from players
    union all select *, 'main', item_3 from players
    union all select *, 'main', item_4 from players
    union all select *, 'main', item_5 from players
    union all select *, 'backpack', backpack_0 from players
    union all select *, 'backpack', backpack_1 from players
    union all select *, 'backpack', backpack_2 from players
    union all select *, 'neutral', item_neutral from players
    union all select *, 'enchantment', item_neutral2 from players
),

held as (
    select distinct
        s.match_id, s.patch_id, s.patch_name, s.hero_id, s.hero_name, s.is_win,
        s.slot_group, s.item_id
    from slots as s
    where s.item_id is not null and s.item_id <> 0
),

consumed as (
    select p.match_id, p.patch_id, p.patch_name, p.hero_id, p.hero_name, p.is_win,
        'consumed' as slot_group, i.item_id
    from players as p
    inner join {{ ref('dim_item') }} as i
        on (i.item_key = 'ultimate_scepter_2' and p.has_aghanims_scepter)
        or (i.item_key = 'aghanims_shard' and p.has_aghanims_shard)
        or (i.item_key = 'moon_shard' and p.has_moon_shard_buff)
),

hero_games as (
    select patch_id, hero_id, count(*) as hero_games
    from players
    group by 1, 2
)

select
    x.patch_id,
    x.patch_name,
    x.hero_id,
    x.hero_name,
    x.slot_group,
    x.item_id,
    i.item_name,
    i.item_cost,
    i.neutral_tier,
    i.is_major_item,
    count(*) as games_with_item,
    sum(case when x.is_win then 1 else 0 end) as wins_with_item,
    hg.hero_games
from (select * from held union all select * from consumed) as x
inner join {{ ref('dim_item') }} as i on i.item_id = x.item_id
inner join hero_games as hg on hg.patch_id = x.patch_id and hg.hero_id = x.hero_id
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13
