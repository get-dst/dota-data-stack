-- Per identified team, hero and patch: how often the team played the hero and won with
-- it, beside how often every pro team played it. The gap between the two
-- (pick_rate_lift) is what makes a hero a team's signature rather than just popular.
-- Only heroes the team played at least once have a row; the rates are per row, for that
-- patch, and do not add up across rows.
with team_matches as (
    select team_id, patch_id, count(distinct match_id) as team_matches
    from {{ ref('fact_player_match') }}
    where team_id is not null
    group by 1, 2
),

patch_matches as (
    select patch_id, count(distinct match_id) as matches
    from {{ ref('fact_player_match') }}
    group by 1
),

field as (
    select p.patch_id, p.hero_id, count(*) * 1.0 / max(pm.matches) as field_pick_rate
    from {{ ref('fact_player_match') }} as p
    inner join patch_matches as pm on pm.patch_id = p.patch_id
    group by 1, 2
),

team_hero as (
    select
        team_id,
        team_name,
        patch_id,
        patch_name,
        hero_id,
        hero_name,
        count(*) as games,
        sum(case when is_win then 1 else 0 end) as wins
    from {{ ref('fact_player_match') }}
    where team_id is not null
    group by 1, 2, 3, 4, 5, 6
)

select
    th.team_id,
    th.team_name,
    th.patch_id,
    th.patch_name,
    th.hero_id,
    th.hero_name,
    th.games,
    th.wins,
    tm.team_matches,
    th.games * 1.0 / tm.team_matches as team_pick_rate,
    f.field_pick_rate,
    th.games * 1.0 / tm.team_matches - f.field_pick_rate as pick_rate_lift
from team_hero as th
inner join team_matches as tm on tm.team_id = th.team_id and tm.patch_id = th.patch_id
inner join field as f on f.patch_id = th.patch_id and f.hero_id = th.hero_id
