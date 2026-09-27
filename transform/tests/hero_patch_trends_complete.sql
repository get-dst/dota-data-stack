-- hero_patch_trends holds every hero in dim_hero on every patch with a loaded pro match,
-- and nothing else, and its picks and bans add up to the pro tables'. A missing zero row
-- would drop that patch's matches from a pick rate summed over several patches. One row
-- per missing or extra hero-patch pair, or per total that does not match.
with expected as (
    select p.patch_id, h.hero_id
    from (select distinct patch_id from {{ ref('fact_match') }}) as p
    cross join {{ ref('dim_hero') }} as h
)

select 'missing' as problem, cast(e.patch_id as varchar) || ':' || cast(e.hero_id as varchar) as detail
from expected as e
left join {{ ref('hero_patch_trends') }} as t on t.patch_id = e.patch_id and t.hero_id = e.hero_id
where t.hero_id is null
union all
select 'outside the window', cast(t.patch_id as varchar) || ':' || cast(t.hero_id as varchar)
from {{ ref('hero_patch_trends') }} as t
left join expected as e on e.patch_id = t.patch_id and e.hero_id = t.hero_id
where e.hero_id is null
union all
select 'picks', cast(t.n as varchar) || ' vs fact_player_match ' || cast(f.n as varchar)
from (select sum(picks) as n from {{ ref('hero_patch_trends') }}) as t,
    (select count(*) as n from {{ ref('fact_player_match') }}) as f
where t.n <> f.n
union all
select 'bans', cast(t.n as varchar) || ' vs fact_draft ' || cast(f.n as varchar)
from (select sum(bans) as n from {{ ref('hero_patch_trends') }}) as t,
    (select count(*) as n from {{ ref('fact_draft') }} where is_ban) as f
where t.n <> f.n
