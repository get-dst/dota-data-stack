-- One row per player per minute of a parsed pro match: gold earned, experience and last
-- hits so far. OpenDota ships each as an array with one value a minute (list index =
-- minute, 0 = the horn); the starting gold is not in it.
select
    m.match_id,
    p.player_slot,
    g._dlt_list_idx as minute,
    g.value as gold,
    x.value as xp,
    l.value as last_hits
from {{ source('raw_behaviour', 'match_details__players__gold_t') }} as g
inner join {{ source('raw', 'match_details__players') }} as p on p._dlt_id = g._dlt_parent_id
inner join {{ source('raw', 'match_details') }} as m on m._dlt_id = p._dlt_parent_id
left join {{ source('raw_behaviour', 'match_details__players__xp_t') }} as x
    on x._dlt_parent_id = g._dlt_parent_id and x._dlt_list_idx = g._dlt_list_idx
left join {{ source('raw_behaviour', 'match_details__players__lh_t') }} as l
    on l._dlt_parent_id = g._dlt_parent_id and l._dlt_list_idx = g._dlt_list_idx
