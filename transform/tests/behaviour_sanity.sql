-- Encodings the behaviour marts rely on. Any row is a broken assumption:
--   a side whose farm shares at minute 10 do not sum to 1;
--   a teamfight without exactly ten player rows (slot_index 0-9 → player_slot).
select 'farm_share_sum' as check_name, cast(match_id as varchar) as detail
from {{ ref('farm_priority') }}
group by match_id, is_radiant
having abs(sum(farm_share_10) - 1) > 0.001
union all
select 'fight_players', cast(match_id as varchar) || ':' || cast(fight_index as varchar)
from {{ ref('stg_teamfight_players') }}
group by match_id, fight_index
having count(distinct player_slot) <> 10 or count(*) <> 10
