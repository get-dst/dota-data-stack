-- Professional players as OpenDota lists them: the name fans know, and the team.
select
    account_id,
    name as player_name,
    personaname as persona_name,
    team_id,
    team_name,
    team_tag,
    country_code,
    fantasy_role,
    last_match_time as last_match_at
from {{ source('raw', 'pro_players') }}
where name is not null and name <> ''
