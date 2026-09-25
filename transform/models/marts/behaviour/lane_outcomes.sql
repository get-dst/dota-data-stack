-- One row per laning player per parsed pro match: the player's lane at 10 minutes against
-- the enemy heroes who laned on the same stretch of map. `lane` is the map lane OpenDota
-- parsed from where each hero stood early (1 bottom, 2 middle, 3 top), so the Radiant
-- safe lane and the Dire off lane are both lane 1; `lane_role` is only the side-relative
-- name for it. Jungle (4, 5) and unparsed lanes are left out, and so is a lane with no
-- enemy hero in it.
--
-- The lane's result belongs to the side, so both laners share it: the side's average gold
-- earned at minute 10 minus the enemy laners' average. Averages, not totals, so a 2v1
-- lane compares heroes to heroes. The draw band is ±{{ var('lane_draw_gold', 400) }} gold
-- (see the lane_result column in schema.yml for why).
with laners as (
    select
        pm.match_id,
        pm.player_slot,
        pm.is_radiant,
        pm.team_id,
        pm.team_name,
        pm.account_id,
        pm.player_name,
        pm.hero_id,
        pm.hero_name,
        pm.position,
        pm.is_win,
        pm.lane,
        pm.lane_role,
        m.gold as gold_10,
        m.last_hits as last_hits_10,
        m.xp as xp_10,
        pm.started_at,
        pm.match_date,
        pm.patch_id,
        pm.patch_name,
        pm.league_id,
        pm.league_name
    from {{ ref('fact_player_match') }} as pm
    inner join {{ ref('stg_player_minutes') }} as m
        on m.match_id = pm.match_id and m.player_slot = pm.player_slot and m.minute = 10
    where pm.lane in (1, 2, 3)
),

sides as (
    select
        match_id,
        lane,
        is_radiant,
        count(*) as heroes,
        avg(gold_10) as avg_gold_10,
        avg(last_hits_10) as avg_last_hits_10,
        avg(xp_10) as avg_xp_10
    from laners
    group by 1, 2, 3
),

compared as (
    select
        l.*,
        own.heroes as own_laners,
        opp.heroes as enemy_laners,
        l.gold_10 - opp.avg_gold_10 as gold_diff_10,
        l.last_hits_10 - opp.avg_last_hits_10 as last_hits_diff_10,
        l.xp_10 - opp.avg_xp_10 as xp_diff_10,
        own.avg_gold_10 - opp.avg_gold_10 as lane_gold_diff_10,
        own.avg_last_hits_10 - opp.avg_last_hits_10 as lane_last_hits_diff_10
    from laners as l
    inner join sides as own
        on own.match_id = l.match_id and own.lane = l.lane and own.is_radiant = l.is_radiant
    inner join sides as opp
        on opp.match_id = l.match_id and opp.lane = l.lane and opp.is_radiant <> l.is_radiant
)

select
    match_id,
    player_slot,
    is_radiant,
    team_id,
    team_name,
    account_id,
    player_name,
    hero_id,
    hero_name,
    position,
    is_win,
    lane,
    lane_role,
    own_laners,
    enemy_laners,
    gold_10,
    last_hits_10,
    xp_10,
    gold_diff_10,
    last_hits_diff_10,
    xp_diff_10,
    lane_gold_diff_10,
    lane_last_hits_diff_10,
    case
        when lane_gold_diff_10 > {{ var('lane_draw_gold', 400) }} then 'won'
        when lane_gold_diff_10 < -{{ var('lane_draw_gold', 400) }} then 'lost'
        else 'drawn'
    end as lane_result,
    started_at,
    match_date,
    patch_id,
    patch_name,
    league_id,
    league_name
from compared
