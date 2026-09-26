-- Damage each player's hero took over the whole match, per source unit (heroes, creeps,
-- neutrals, towers, Roshan) by internal key. A hero's own key appears too: self-damage
-- (Centaur's Double Edge, Huskar's spells); marts decide which sources count.
select
    m.match_id,
    p.player_slot,
    d.source_key,
    d.amount
from {{ source('raw_behaviour', 'match_details__players__damage_taken') }} as d
inner join {{ source('raw', 'match_details__players') }} as p on p._dlt_id = d._dlt_parent_id
inner join {{ ref('stg_matches') }} as m on m._dlt_id = p._dlt_parent_id
