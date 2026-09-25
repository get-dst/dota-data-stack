-- One row per player per parsed pro match: how much of the side's farm went to this
-- player. Gold is gold earned since the horn from OpenDota's per-minute curve (starting
-- gold not included), so a share is this player's gold over the five players' gold at
-- that minute. Minute-20 columns are null when the match ended before minute 20.
with at_minute as (
    select
        match_id,
        player_slot,
        max(case when minute = 10 then gold end) as gold_10,
        max(case when minute = 20 then gold end) as gold_20,
        max(case when minute = 10 then last_hits end) as last_hits_10,
        max(case when minute = 20 then last_hits end) as last_hits_20
    from {{ ref('stg_player_minutes') }}
    where minute in (10, 20)
    group by 1, 2
),

base as (
    select
        pm.*,
        a.gold_10,
        a.gold_20,
        a.last_hits_10,
        a.last_hits_20
    from {{ ref('fact_player_match') }} as pm
    inner join at_minute as a on a.match_id = pm.match_id and a.player_slot = pm.player_slot
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
    gold_10,
    sum(gold_10) over (partition by match_id, is_radiant) as team_gold_10,
    gold_10 * 1.0 / nullif(sum(gold_10) over (partition by match_id, is_radiant), 0) as farm_share_10,
    gold_20,
    sum(gold_20) over (partition by match_id, is_radiant) as team_gold_20,
    gold_20 * 1.0 / nullif(sum(gold_20) over (partition by match_id, is_radiant), 0) as farm_share_20,
    last_hits_10,
    last_hits_20,
    rank() over (partition by match_id, is_radiant order by gold_10 desc) as farm_rank_10,
    net_worth,
    rank() over (partition by match_id, is_radiant order by net_worth desc) as networth_rank,
    started_at,
    match_date,
    patch_id,
    patch_name,
    league_id,
    league_name,
    duration_min
from base
