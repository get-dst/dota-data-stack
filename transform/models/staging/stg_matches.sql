-- One row per pro match with full detail. Epoch seconds become timestamps here and
-- nowhere else; the raw columns keep OpenDota's names. The inner join to stg_leagues
-- keeps only matches in a league OpenDota rates premium or professional; the child
-- staging models join here on _dlt_id, so they carry the same matches. Team and league
-- names are trimmed (clean_name); a blank team record name falls back to the match's
-- own name field.
select
    m.match_id,
    to_timestamp(start_time) as started_at,
    duration as duration_s,
    radiant_win,
    radiant_score,
    dire_score,
    radiant_team_id,
    coalesce({{ clean_name('radiant_team__name') }}, {{ clean_name('radiant_name') }}) as radiant_team_name,
    dire_team_id,
    coalesce({{ clean_name('dire_team__name') }}, {{ clean_name('dire_name') }}) as dire_team_name,
    leagueid as league_id,
    {{ clean_name('league__name') }} as league_name,
    l.league_tier,
    patch as patch_id,
    game_mode as game_mode_id,
    lobby_type as lobby_type_id,
    region as region_id,
    series_id,
    series_type,
    first_blood_time as first_blood_s,
    tower_status_radiant,
    tower_status_dire,
    barracks_status_radiant,
    barracks_status_dire,
    comeback,
    stomp,
    human_players,
    m._dlt_id
from {{ source('raw', 'match_details') }} as m
inner join {{ ref('stg_leagues') }} as l on l.league_id = m.leagueid
