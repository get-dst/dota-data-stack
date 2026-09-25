-- A Captains Mode draft is six runs (ban, pick, ban, pick, ban, pick) with five picks per
-- side. A pick or ban outside those runs, or a side without five picks, is a draft of a
-- shape draft_phases does not understand.
select match_id, 'no phase' as problem
from {{ ref('draft_phases') }}
where draft_phase is null
union all
select match_id, 'not five picks' as problem
from {{ ref('draft_phases') }}
group by match_id, is_radiant
having sum(case when is_pick then 1 else 0 end) <> 5
