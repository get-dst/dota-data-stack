-- One row per player per parsed pro match: how the player took part in the match's
-- teamfights, as OpenDota's parser marks them (a window with several hero deaths close
-- together). A player is present in a fight when, inside its window, they damaged or
-- healed a hero, died or got a kill. Parsed = the match has per-minute gold rows; a
-- parsed match can have no teamfights, and then participation is null.
with parsed as (
    select distinct match_id from {{ ref('stg_player_minutes') }}
),

fights as (
    select
        match_id,
        player_slot,
        count(*) as match_fights,
        count(case when damage > 0 or healing > 0 or deaths > 0 or kills > 0 then 1 end) as fights_present,
        sum(kills) as fight_kills,
        sum(deaths) as fight_deaths,
        sum(buybacks) as fight_buybacks,
        sum(damage) as fight_damage,
        sum(healing) as fight_healing,
        sum(gold_delta) as fight_gold_delta,
        sum(xp_delta) as fight_xp_delta
    from {{ ref('stg_teamfight_players') }}
    group by 1, 2
)

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
    {{ position_name('pm.position') }} as position_name,
    pm.is_win,
    coalesce(f.match_fights, 0) as match_fights,
    coalesce(f.fights_present, 0) as fights_present,
    f.fights_present * 1.0 / nullif(f.match_fights, 0) as fight_participation,
    coalesce(f.fight_kills, 0) as fight_kills,
    coalesce(f.fight_deaths, 0) as fight_deaths,
    pm.deaths as total_deaths,
    greatest(pm.deaths - coalesce(f.fight_deaths, 0), 0) as deaths_outside_fights,
    coalesce(f.fight_buybacks, 0) as fight_buybacks,
    coalesce(f.fight_damage, 0) as fight_damage,
    coalesce(f.fight_healing, 0) as fight_healing,
    coalesce(f.fight_gold_delta, 0) as fight_gold_delta,
    coalesce(f.fight_xp_delta, 0) as fight_xp_delta,
    pm.started_at,
    pm.match_date,
    pm.patch_id,
    pm.patch_name,
    pm.league_id,
    pm.league_name,
    pm.duration_min
from {{ ref('fact_player_match') }} as pm
inner join parsed as p on p.match_id = pm.match_id
left join fights as f on f.match_id = pm.match_id and f.player_slot = pm.player_slot
