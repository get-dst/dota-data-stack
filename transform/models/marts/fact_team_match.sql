-- Two rows per pro match, one per side: the team grain. A team's matches are counted
-- here and nowhere else; fact_player_match has five rows per side, so counting it
-- overstates a team's matches five times. team_id is null when OpenDota did not tie
-- the side to a team (the row stays, so every match has exactly two rows and exactly
-- one win). has_first_pick is null when the match has no recorded draft.
with sides as (
    select
        match_id,
        true as is_radiant,
        'radiant' as side,
        radiant_team_id as team_id,
        radiant_team_name as team_name,
        dire_team_id as opponent_team_id,
        dire_team_name as opponent_team_name,
        radiant_win as is_win,
        radiant_kills as kills,
        dire_kills as kills_against
    from {{ ref('fact_match') }}
    union all
    select
        match_id,
        false,
        'dire',
        dire_team_id,
        dire_team_name,
        radiant_team_id,
        radiant_team_name,
        not radiant_win,
        dire_kills,
        radiant_kills
    from {{ ref('fact_match') }}
),

first_picks as (
    select match_id, is_radiant as first_pick_is_radiant
    from {{ ref('fact_draft') }}
    where is_pick
    qualify row_number() over (partition by match_id order by draft_order) = 1
)

select
    s.match_id,
    s.is_radiant,
    s.side,
    s.team_id,
    s.team_name,
    s.opponent_team_id,
    s.opponent_team_name,
    s.is_win,
    s.kills,
    s.kills_against,
    s.is_radiant = f.first_pick_is_radiant as has_first_pick,
    m.started_at,
    m.match_date,
    m.duration_min,
    m.patch_id,
    m.patch_name,
    m.league_id,
    m.league_name,
    m.league_tier,
    m.game_mode_id,
    m.series_id,
    m.series_type
from sides as s
inner join {{ ref('fact_match') }} as m on m.match_id = s.match_id
left join first_picks as f on f.match_id = s.match_id
