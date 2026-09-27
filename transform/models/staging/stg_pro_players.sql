-- Professional players as OpenDota lists them: the name fans know, and the team.
-- Names are trimmed (clean_name); an empty country code is null.
select
    account_id,
    {{ clean_name('name') }} as player_name,
    {{ clean_name('personaname') }} as persona_name,
    team_id,
    {{ clean_name('team_name') }} as team_name,
    {{ clean_name('team_tag') }} as team_tag,
    nullif(trim(country_code), '') as country_code,
    fantasy_role,
    last_match_time as last_match_at
from {{ source('raw', 'pro_players') }}
where {{ clean_name('name') }} is not null
