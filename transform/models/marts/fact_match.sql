-- One row per pro match. Winner is resolved to a team id here so "who won" never
-- depends on remembering which side is Radiant.
select
    m.match_id,
    m.started_at,
    cast(timezone('UTC', m.started_at) as date) as match_date,  -- UTC, whoever runs dbt
    m.duration_s,
    m.duration_s / 60.0 as duration_min,
    m.radiant_win,
    case when m.radiant_win then m.radiant_team_id else m.dire_team_id end as winner_team_id,
    case when m.radiant_win then m.dire_team_id else m.radiant_team_id end as loser_team_id,
    m.radiant_team_id,
    m.radiant_team_name,
    m.dire_team_id,
    m.dire_team_name,
    m.radiant_score as radiant_kills,
    m.dire_score as dire_kills,
    m.radiant_score + m.dire_score as total_kills,
    m.league_id,
    m.league_name,
    m.league_tier,
    m.patch_id,
    p.patch_name,
    m.game_mode_id,
    m.lobby_type_id,
    m.region_id,
    m.series_id,
    m.series_type,
    m.first_blood_s,
    m.first_blood_s / 60.0 as first_blood_min,
    m.comeback,
    m.stomp
from {{ ref('stg_matches') }} as m
left join {{ ref('stg_patches') }} as p on p.patch_id = m.patch_id
