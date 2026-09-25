-- One row per player per pro match: the performance grain. Position (1-5) is derived
-- from the lane OpenDota parsed and the player's farm rank inside the side: mid is 2;
-- the richer safe-laner is the carry (1) and the poorer the hard support (5); the
-- richer offlaner is 3 and the poorer is 4. A convention, stated in the entity file.
with ranked as (
    select
        pm.*,
        row_number() over (
            partition by pm.match_id, pm.is_radiant, pm.lane_role
            order by pm.gold_per_min desc
        ) as farm_rank_in_lane
    from {{ ref('stg_match_players') }} as pm
)

select
    pm.match_id,
    pm.player_slot,
    pm.is_radiant,
    case when pm.is_radiant then m.radiant_team_id else m.dire_team_id end as team_id,
    case when pm.is_radiant then m.radiant_team_name else m.dire_team_name end as team_name,
    pm.account_id,
    coalesce(pp.player_name, pm.player_name) as player_name,
    pp.player_name as pro_name,
    pp.country_code as player_country,
    pm.hero_id,
    h.hero_name,
    pm.is_win,
    pm.kills,
    pm.deaths,
    pm.assists,
    pm.kda,
    pm.last_hits,
    pm.denies,
    pm.gold_per_min,
    pm.xp_per_min,
    pm.level,
    pm.net_worth,
    pm.hero_damage,
    pm.tower_damage,
    pm.hero_healing,
    pm.obs_placed,
    pm.sen_placed,
    pm.camps_stacked,
    pm.rune_pickups,
    pm.roshans_killed,
    pm.towers_killed,
    pm.teamfight_participation,
    pm.stuns,
    pm.item_0,
    pm.item_1,
    pm.item_2,
    pm.item_3,
    pm.item_4,
    pm.item_5,
    pm.item_neutral,
    pm.aghanims_scepter = 1 as has_aghanims_scepter,
    pm.aghanims_shard = 1 as has_aghanims_shard,
    pm.lane,
    pm.lane_role,
    pm.is_roaming,
    case
        when pm.lane_role = 2 then 2
        when pm.lane_role = 1 and pm.farm_rank_in_lane = 1 then 1
        when pm.lane_role = 1 then 5
        when pm.lane_role = 3 and pm.farm_rank_in_lane = 1 then 3
        when pm.lane_role = 3 then 4
        else null
    end as position,
    pm.leaver_status,
    pm.abandons,
    m.started_at,
    m.match_date,
    m.patch_id,
    m.patch_name,
    m.league_id,
    m.league_name,
    m.duration_min
from ranked as pm
inner join {{ ref('fact_match') }} as m on m.match_id = pm.match_id
left join {{ ref('stg_heroes') }} as h on h.hero_id = pm.hero_id
left join {{ ref('stg_pro_players') }} as pp on pp.account_id = pm.account_id
