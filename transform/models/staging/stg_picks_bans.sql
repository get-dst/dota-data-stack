-- Draft order per match. team 0 = Radiant, 1 = Dire in OpenDota's encoding.
select
    m.match_id,
    pb."order" as draft_order,
    pb.is_pick,
    pb.hero_id,
    pb.team = 0 as is_radiant
from {{ source('raw', 'match_details__picks_bans') }} as pb
inner join {{ source('raw', 'match_details') }} as m on m._dlt_id = pb._dlt_parent_id
