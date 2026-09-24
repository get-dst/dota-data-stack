-- Pro matches between two teams, from each team's point of view: both orderings
-- are present, so a question can start from either team.
with sides as (
    select match_id, patch_id, patch_name, league_name, match_date,
        radiant_team_id as team_id, radiant_team_name as team_name,
        dire_team_id as opponent_team_id, dire_team_name as opponent_team_name,
        radiant_win as is_win
    from {{ ref('fact_match') }}
    union all
    select match_id, patch_id, patch_name, league_name, match_date,
        dire_team_id, dire_team_name, radiant_team_id, radiant_team_name,
        not radiant_win
    from {{ ref('fact_match') }}
)

select
    team_id,
    team_name,
    opponent_team_id,
    opponent_team_name,
    patch_id,
    patch_name,
    count(*) as matches,
    sum(case when is_win then 1 else 0 end) as wins,
    min(match_date) as first_match_date,
    max(match_date) as last_match_date
from sides
where team_id is not null and opponent_team_id is not null
group by 1, 2, 3, 4, 5, 6
