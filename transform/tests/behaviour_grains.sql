-- The behaviour marts each have one row per their declared grain; any row here is a
-- duplicate key (a fan-out in the joins).
select 'player_fight_stats' as model, cast(match_id as varchar) || ':' || cast(player_slot as varchar) as grain_key
from {{ ref('player_fight_stats') }} group by match_id, player_slot having count(*) > 1
union all
select 'farm_priority', cast(match_id as varchar) || ':' || cast(player_slot as varchar)
from {{ ref('farm_priority') }} group by match_id, player_slot having count(*) > 1
union all
select 'lane_outcomes', cast(match_id as varchar) || ':' || cast(player_slot as varchar)
from {{ ref('lane_outcomes') }} group by match_id, player_slot having count(*) > 1
union all
select 'space_created', cast(match_id as varchar) || ':' || cast(player_slot as varchar)
from {{ ref('space_created') }} group by match_id, player_slot having count(*) > 1
union all
select 'vision_and_runes', cast(match_id as varchar) || ':' || cast(player_slot as varchar)
from {{ ref('vision_and_runes') }} group by match_id, player_slot having count(*) > 1
union all
select 'hero_playstyle', cast(patch_id as varchar) || ':' || cast(hero_id as varchar) || ':' || cast(position as varchar)
from {{ ref('hero_playstyle') }} group by patch_id, hero_id, position having count(*) > 1
union all
select 'player_playstyle', cast(patch_id as varchar) || ':' || cast(account_id as varchar)
from {{ ref('player_playstyle') }} group by patch_id, account_id having count(*) > 1
