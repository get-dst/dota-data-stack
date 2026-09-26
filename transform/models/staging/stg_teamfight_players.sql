-- Ten rows per teamfight of a pro match, one per player. OpenDota lists a fight's players
-- in player order, so the list index 0-9 is player_slot 0-4 then 128-132 (checked against
-- the kills log: the heroes OpenDota counts dead in a fight are the victims logged in its
-- window). damage and healing are to heroes only, during the fight's window.
select
    m.match_id,
    f._dlt_list_idx as fight_index,
    f.start as fight_start_s,
    f."end" as fight_end_s,
    f.deaths as fight_deaths,
    case when tp.slot_index < 5 then tp.slot_index else tp.slot_index + 123 end as player_slot,
    tp.deaths,
    tp.buybacks,
    tp.damage,
    tp.healing,
    tp.gold_delta,
    tp.xp_delta,
    coalesce(k.kills, 0) as kills
from {{ source('raw_behaviour', 'match_details__teamfights__players') }} as tp
inner join {{ source('raw_behaviour', 'match_details__teamfights') }} as f on f._dlt_id = tp._dlt_parent_id
inner join {{ ref('stg_matches') }} as m on m._dlt_id = f._dlt_parent_id
left join (
    select _dlt_parent_id, sum(count) as kills
    from {{ source('raw_behaviour', 'match_details__teamfights__players__killed') }}
    group by 1
) as k on k._dlt_parent_id = tp._dlt_id
