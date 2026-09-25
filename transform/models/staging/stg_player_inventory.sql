-- The end-of-game slots stg_match_players leaves out: backpack, the second neutral slot
-- (the enchantment) and the consumed Moon Shard buff. One row per player per pro match.
select
    m.match_id,
    p.player_slot,
    p.backpack_0,
    p.backpack_1,
    p.backpack_2,
    p.item_neutral2,
    p.moonshard = 1 as has_moon_shard_buff
from {{ source('raw', 'match_details__players') }} as p
inner join {{ source('raw', 'match_details') }} as m on m._dlt_id = p._dlt_parent_id
