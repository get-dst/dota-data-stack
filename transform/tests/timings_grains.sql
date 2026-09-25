-- The timings marts each have one row per their declared grain; any row here is a
-- duplicate key.
select 'gold_advantage_timeline' as model, cast(match_id as varchar) || ':' || cast(minute as varchar) as grain_key
from {{ ref('gold_advantage_timeline') }}
group by match_id, minute
having count(*) > 1
union all
select 'objective_win_rates', cast(patch_id as varchar) || ':' || objective
from {{ ref('objective_win_rates') }}
group by patch_id, objective
having count(*) > 1
union all
select 'hero_patch_trends', cast(patch_id as varchar) || ':' || cast(hero_id as varchar)
from {{ ref('hero_patch_trends') }}
group by patch_id, hero_id
having count(*) > 1
union all
select 'hero_position_meta', cast(patch_id as varchar) || ':' || cast(hero_id as varchar) || ':' || cast(position as varchar)
from {{ ref('hero_position_meta') }}
group by patch_id, hero_id, position
having count(*) > 1
