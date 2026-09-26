-- Pro models hold only matches in leagues OpenDota rates premium or professional (the
-- rule in stg_leagues). Checked against the raw league list, not against the rule's
-- own output, so a model that reads the raw match tables directly is caught too. The
-- team rollups carry no match id, so their match counts must equal fact_team_match's.
-- One row per offending model and match, league or count.
with pro_matches as (
    select distinct 'stg_matches' as model, match_id from {{ ref('stg_matches') }}
    union all select distinct 'fact_match', match_id from {{ ref('fact_match') }}
    union all select distinct 'fact_team_match', match_id from {{ ref('fact_team_match') }}
    union all select distinct 'fact_player_match', match_id from {{ ref('fact_player_match') }}
    union all select distinct 'fact_draft', match_id from {{ ref('fact_draft') }}
    union all select distinct 'draft_phases', match_id from {{ ref('draft_phases') }}
    union all select distinct 'team_lineups', match_id from {{ ref('team_lineups') }}
    union all select distinct 'gold_advantage_timeline', match_id from {{ ref('gold_advantage_timeline') }}
    union all select distinct 'match_leads', match_id from {{ ref('match_leads') }}
    union all select distinct 'match_objectives', match_id from {{ ref('match_objectives') }}
    union all select distinct 'player_fight_stats', match_id from {{ ref('player_fight_stats') }}
    union all select distinct 'farm_priority', match_id from {{ ref('farm_priority') }}
    union all select distinct 'lane_outcomes', match_id from {{ ref('lane_outcomes') }}
    union all select distinct 'space_created', match_id from {{ ref('space_created') }}
    union all select distinct 'vision_and_runes', match_id from {{ ref('vision_and_runes') }}
),

pro_leagues as (
    select distinct 'league_standings' as model, league_id from {{ ref('league_standings') }}
    union all select distinct 'dim_league', league_id from {{ ref('dim_league') }}
),

raw_tier as (
    select md.match_id, l.tier
    from {{ source('raw', 'match_details') }} as md
    left join {{ source('raw', 'leagues') }} as l on l.leagueid = md.leagueid
)

select p.model, p.match_id as id, coalesce(r.tier, 'unrated') as tier
from pro_matches as p
left join raw_tier as r on r.match_id = p.match_id
where coalesce(r.tier, 'unrated') not in ('premium', 'professional')
union all
select p.model, p.league_id, coalesce(l.tier, 'unrated')
from pro_leagues as p
left join {{ source('raw', 'leagues') }} as l on l.leagueid = p.league_id
where coalesce(l.tier, 'unrated') not in ('premium', 'professional')
union all
select 'dim_team.loaded_matches', null, cast(d.n as varchar) || ' sides, fact_team_match ' || cast(f.n as varchar)
from (select sum(loaded_matches) as n from {{ ref('dim_team') }}) as d,
    (select count(*) as n from {{ ref('fact_team_match') }} where team_id is not null) as f
where d.n <> f.n
union all
select 'team_head_to_head.matches', null, cast(h.n as varchar) || ' sides, fact_team_match ' || cast(f.n as varchar)
from (select sum(matches) as n from {{ ref('team_head_to_head') }}) as h,
    (select count(*) as n from {{ ref('fact_team_match') }}
     where team_id is not null and opponent_team_id is not null) as f
where h.n <> f.n
