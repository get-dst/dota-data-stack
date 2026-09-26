-- One row per pro match per minute: the Radiant side's gold and XP advantage. OpenDota
-- ships each as an array with one value a minute; dlt lands it as a child table whose
-- list index is the minute (0 = the horn). Positive = Radiant ahead, negative = Dire.
select
    m.match_id,
    g._dlt_list_idx as minute,
    g.value as radiant_gold_adv,
    x.value as radiant_xp_adv
from {{ source('raw_timings', 'match_details__radiant_gold_adv') }} as g
inner join {{ ref('stg_matches') }} as m on m._dlt_id = g._dlt_parent_id
left join {{ source('raw_timings', 'match_details__radiant_xp_adv') }} as x
    on x._dlt_parent_id = g._dlt_parent_id and x._dlt_list_idx = g._dlt_list_idx
