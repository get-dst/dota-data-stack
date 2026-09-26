-- Every hero kill in a pro match, from the killer's kills log: when, and which hero died
-- (victim_hero_key is the victim's internal hero key; a hero appears once per match in
-- Captains Mode, so the key names the victim's player). Deaths to creeps, towers,
-- Roshan or a deny are not hero kills and are not here.
select
    m.match_id,
    p.player_slot as killer_slot,
    k.time as time_s,
    k.key as victim_hero_key,
    coalesce(k.smoke, false) as under_smoke
from {{ source('raw_behaviour', 'match_details__players__kills_log') }} as k
inner join {{ source('raw', 'match_details__players') }} as p on p._dlt_id = k._dlt_parent_id
inner join {{ ref('stg_matches') }} as m on m._dlt_id = p._dlt_parent_id
