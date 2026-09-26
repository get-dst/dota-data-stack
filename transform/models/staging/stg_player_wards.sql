-- Every observer and sentry ward a player placed in a pro match: when (seconds from the
-- horn, negative before it) and where (OpenDota's 0-256 map grid).
select
    m.match_id,
    p.player_slot,
    'observer' as ward_type,
    o.time as time_s,
    o.x,
    o.y
from {{ source('raw_behaviour', 'match_details__players__obs_log') }} as o
inner join {{ source('raw', 'match_details__players') }} as p on p._dlt_id = o._dlt_parent_id
inner join {{ ref('stg_matches') }} as m on m._dlt_id = p._dlt_parent_id
union all
select
    m.match_id,
    p.player_slot,
    'sentry' as ward_type,
    s.time as time_s,
    s.x,
    s.y
from {{ source('raw_behaviour', 'match_details__players__sen_log') }} as s
inner join {{ source('raw', 'match_details__players') }} as p on p._dlt_id = s._dlt_parent_id
inner join {{ ref('stg_matches') }} as m on m._dlt_id = p._dlt_parent_id
