-- Every buyback in a pro match: who, and when (seconds from the horn).
select
    m.match_id,
    p.player_slot,
    b.time as time_s
from {{ source('raw_behaviour', 'match_details__players__buyback_log') }} as b
inner join {{ source('raw', 'match_details__players') }} as p on p._dlt_id = b._dlt_parent_id
inner join {{ source('raw', 'match_details') }} as m on m._dlt_id = p._dlt_parent_id
