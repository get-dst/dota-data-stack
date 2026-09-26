-- Every rune a player took (picked up or bottled) in a pro match, with its type. OpenDota's
-- rune codes, checked against spawn times in the data (bounties at 0:00, water at 2:00
-- and 4:00, wisdom at 7:00, power runes from 6:00): 0 double damage, 1 haste, 2 illusion,
-- 3 invisibility, 4 regeneration, 5 bounty, 6 arcane, 7 water, 8 wisdom, 9 shield.
select
    m.match_id,
    p.player_slot,
    r.time as time_s,
    cast(r.key as integer) as rune_code,
    case cast(r.key as integer)
        when 0 then 'double_damage'
        when 1 then 'haste'
        when 2 then 'illusion'
        when 3 then 'invisibility'
        when 4 then 'regeneration'
        when 5 then 'bounty'
        when 6 then 'arcane'
        when 7 then 'water'
        when 8 then 'wisdom'
        when 9 then 'shield'
    end as rune_type
from {{ source('raw_behaviour', 'match_details__players__runes_log') }} as r
inner join {{ source('raw', 'match_details__players') }} as p on p._dlt_id = r._dlt_parent_id
inner join {{ ref('stg_matches') }} as m on m._dlt_id = p._dlt_parent_id
