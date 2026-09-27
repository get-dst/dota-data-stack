-- Team, league and player names enter the project in these staging models and are
-- trimmed there (clean_name), so a filter on "Nigma Galaxy" matches every row of the
-- team. A name here has no leading or trailing space and is never blank; a country
-- code is null or two letters, never ''. One row per offending model, column and value.
with names as (
    select 'stg_teams' as model, 'team_name' as col, team_name as val from {{ ref('stg_teams') }}
    union all select 'stg_teams', 'team_tag', team_tag from {{ ref('stg_teams') }}
    union all select 'stg_matches', 'radiant_team_name', radiant_team_name from {{ ref('stg_matches') }}
    union all select 'stg_matches', 'dire_team_name', dire_team_name from {{ ref('stg_matches') }}
    union all select 'stg_matches', 'league_name', league_name from {{ ref('stg_matches') }}
    union all select 'stg_leagues', 'league_name', league_name from {{ ref('stg_leagues') }}
    union all select 'stg_pro_players', 'player_name', player_name from {{ ref('stg_pro_players') }}
    union all select 'stg_pro_players', 'team_name', team_name from {{ ref('stg_pro_players') }}
    union all select 'stg_match_players', 'player_name', player_name from {{ ref('stg_match_players') }}
    union all select 'dim_team', 'team_name', team_name from {{ ref('dim_team') }}
)

select model, col, val
from names
where val <> trim(val) or val = ''
union all
select 'stg_pro_players', 'country_code', country_code
from {{ ref('stg_pro_players') }}
where country_code = '' or length(country_code) <> 2
