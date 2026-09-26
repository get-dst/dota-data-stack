-- One row per professional team: every team in OpenDota's ranking (the top thousand by
-- rating, with rating and all-time records) and every team identified on a loaded pro
-- match (stg_matches: premium and professional leagues only), so a team id on a match
-- always resolves here. The ranking covers few of the teams that actually play in the
-- window; a team outside it has its name from its latest loaded match and null rating,
-- tag and all-time records.
with match_sides as (
    select radiant_team_id as team_id, radiant_team_name as team_name, started_at
    from {{ ref('stg_matches') }}
    union all
    select dire_team_id, dire_team_name, started_at
    from {{ ref('stg_matches') }}
),

match_teams as (
    select
        team_id,
        arg_max(team_name, started_at) as team_name,
        count(*) as loaded_matches,
        max(started_at) as last_loaded_match_at
    from match_sides
    where team_id is not null
    group by 1
)

select
    coalesce(r.team_id, m.team_id) as team_id,
    coalesce(r.team_name, m.team_name) as team_name,
    r.team_tag,
    r.rating,
    r.all_time_wins,
    r.all_time_losses,
    r.last_match_at,
    r.team_id is not null as is_ranked,
    coalesce(m.loaded_matches, 0) as loaded_matches,
    m.last_loaded_match_at
from {{ ref('stg_teams') }} as r
full outer join match_teams as m on m.team_id = r.team_id
