-- Encodings the behaviour marts rely on. Any row is a broken assumption:
--   a per-minute sample whose time is not minute × 60 (list index = minute);
--   a side whose farm shares at minute 10 do not sum to 1;
--   a teamfight without exactly ten player rows (slot_index 0-9 → player_slot).
select 'minute_index' as check_name, cast(count(*) as varchar) as detail
from {{ source('raw_behaviour', 'match_details__players__times') }}
where value <> _dlt_list_idx * 60
having count(*) > 0
union all
select 'farm_share_sum', cast(match_id as varchar)
from {{ ref('farm_priority') }}
group by match_id, is_radiant
having abs(sum(farm_share_10) - 1) > 0.001
union all
select 'fight_players', cast(match_id as varchar) || ':' || cast(fight_index as varchar)
from {{ ref('stg_teamfight_players') }}
group by match_id, fight_index
having count(distinct player_slot) <> 10 or count(*) <> 10
