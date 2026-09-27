-- Per patch and pro player (by Steam account) over parsed pro matches: the same fight,
-- farm, lane, space and vision measures as hero_playstyle, for questions about named
-- players. `games` is the sample size every ranking must check (the
-- playstyle_minimum_games definition). player_name is the name on the player's latest
-- match of the patch (the pro name when OpenDota lists the account as a pro); pro_name
-- is the name from dim_pro_player, null for accounts OpenDota does not list as pro;
-- main_position is the position the player played most on the patch.
with pos as (
    select
        patch_id,
        account_id,
        position,
        row_number() over (partition by patch_id, account_id order by count(*) desc, position) as rn
    from {{ ref('player_fight_stats') }}
    where position is not null and account_id is not null
    group by 1, 2, 3
),

names as (
    select
        patch_id,
        account_id,
        player_name,
        row_number() over (partition by patch_id, account_id order by started_at desc, match_id desc) as rn
    from {{ ref('player_fight_stats') }}
    where account_id is not null
)

select
    f.patch_id,
    f.patch_name,
    f.account_id,
    max(n.player_name) as player_name,
    max(pp.player_name) as pro_name,
    max(p.position) as main_position,
    {{ position_name('max(p.position)') }} as main_position_name,
    count(*) as games,
    count(case when f.is_win then 1 end) as wins,
    sum(f.duration_min) as game_minutes,
    sum(f.match_fights) as match_fights,
    sum(f.fights_present) as fights_present,
    sum(f.fights_present) * 1.0 / nullif(sum(f.match_fights), 0) as fight_participation,
    sum(f.fight_kills) as fight_kills,
    sum(f.fight_deaths) as fight_deaths,
    sum(f.deaths_outside_fights) as deaths_outside_fights,
    sum(f.fight_damage) as fight_damage,
    sum(f.fight_gold_delta) as fight_gold_delta,
    avg(f.fight_gold_delta) as avg_fight_gold_delta,
    count(fp.farm_share_10) as farm_games_10,
    sum(fp.farm_share_10) as farm_share_10_total,
    avg(fp.farm_share_10) as avg_farm_share_10,
    count(fp.farm_share_20) as farm_games_20,
    sum(fp.farm_share_20) as farm_share_20_total,
    avg(fp.farm_share_20) as avg_farm_share_20,
    sum(fp.last_hits_10) as last_hits_10_total,
    avg(fp.last_hits_10) as avg_last_hits_10,
    count(lo.lane_result) as lane_games,
    count(case when lo.lane_result = 'won' then 1 end) as lanes_won,
    count(case when lo.lane_result = 'drawn' then 1 end) as lanes_drawn,
    count(case when lo.lane_result = 'lost' then 1 end) as lanes_lost,
    count(case when lo.lane_result = 'won' then 1 end) * 1.0 / nullif(count(lo.lane_result), 0) as lane_win_rate,
    avg(lo.lane_gold_diff_10) as avg_lane_gold_diff_10,
    sum(s.enemy_hero_damage_taken) as enemy_hero_damage_taken,
    sum(s.enemy_hero_damage_taken) / nullif(sum(f.duration_min), 0) as enemy_hero_damage_taken_per_min,
    sum(s.hero_kill_deaths) as hero_kill_deaths,
    sum(s.trade_deaths) as trade_deaths,
    sum(s.trade_deaths) * 1.0 / nullif(sum(s.hero_kill_deaths), 0) as trade_death_share,
    sum(v.observers_placed) as observers_placed,
    sum(v.sentries_placed) as sentries_placed,
    sum(v.runes_taken) as runes_taken,
    sum(v.buybacks) as buybacks
from {{ ref('player_fight_stats') }} as f
left join names as n on n.patch_id = f.patch_id and n.account_id = f.account_id and n.rn = 1
left join pos as p on p.patch_id = f.patch_id and p.account_id = f.account_id and p.rn = 1
left join {{ ref('dim_pro_player') }} as pp on pp.account_id = f.account_id
left join {{ ref('farm_priority') }} as fp on fp.match_id = f.match_id and fp.player_slot = f.player_slot
left join {{ ref('lane_outcomes') }} as lo on lo.match_id = f.match_id and lo.player_slot = f.player_slot
left join {{ ref('space_created') }} as s on s.match_id = f.match_id and s.player_slot = f.player_slot
left join {{ ref('vision_and_runes') }} as v on v.match_id = f.match_id and v.player_slot = f.player_slot
where f.account_id is not null
group by 1, 2, 3
