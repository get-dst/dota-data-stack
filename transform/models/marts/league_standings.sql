-- Each team's record inside each league, from the pro matches loaded.
with sides as (
    select match_id, league_id, league_name, match_date,
        radiant_team_id as team_id, radiant_team_name as team_name, radiant_win as is_win
    from {{ ref('fact_match') }}
    union all
    select match_id, league_id, league_name, match_date,
        dire_team_id, dire_team_name, not radiant_win
    from {{ ref('fact_match') }}
)

select
    league_id,
    league_name,
    team_id,
    team_name,
    count(*) as matches,
    sum(case when is_win then 1 else 0 end) as wins,
    count(*) - sum(case when is_win then 1 else 0 end) as losses,
    min(match_date) as first_match_date,
    max(match_date) as last_match_date
from sides
where team_id is not null
group by 1, 2, 3, 4
