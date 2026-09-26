-- One row per player per parsed pro match: wards placed (from the ward logs), runes taken
-- by type (from the rune log: picked up or bottled), and buybacks with their timing.
with players as (
    select pm.*
    from {{ ref('fact_player_match') }} as pm
    where pm.match_id in (select match_id from {{ ref('stg_player_minutes') }})
),

wards as (
    select
        match_id,
        player_slot,
        count(case when ward_type = 'observer' then 1 end) as observers_placed,
        count(case when ward_type = 'sentry' then 1 end) as sentries_placed,
        count(case when ward_type = 'observer' and time_s < 600 then 1 end) as observers_before_10,
        count(case when ward_type = 'sentry' and time_s < 600 then 1 end) as sentries_before_10
    from {{ ref('stg_player_wards') }}
    group by 1, 2
),

runes as (
    select
        match_id,
        player_slot,
        count(*) as runes_taken,
        count(case when rune_type = 'bounty' then 1 end) as bounty_runes,
        count(case when rune_type in ('double_damage', 'haste', 'illusion', 'invisibility', 'regeneration', 'arcane', 'shield') then 1 end) as power_runes,
        count(case when rune_type = 'water' then 1 end) as water_runes,
        count(case when rune_type = 'wisdom' then 1 end) as wisdom_runes,
        count(case when rune_type = 'double_damage' then 1 end) as double_damage_runes,
        count(case when rune_type = 'haste' then 1 end) as haste_runes,
        count(case when rune_type = 'illusion' then 1 end) as illusion_runes,
        count(case when rune_type = 'invisibility' then 1 end) as invisibility_runes,
        count(case when rune_type = 'regeneration' then 1 end) as regeneration_runes,
        count(case when rune_type = 'arcane' then 1 end) as arcane_runes,
        count(case when rune_type = 'shield' then 1 end) as shield_runes
    from {{ ref('stg_player_runes') }}
    group by 1, 2
),

buybacks as (
    select
        match_id,
        player_slot,
        count(*) as buybacks,
        min(time_s) / 60.0 as first_buyback_min
    from {{ ref('stg_player_buybacks') }}
    group by 1, 2
)

select
    p.match_id,
    p.player_slot,
    p.is_radiant,
    p.team_id,
    p.team_name,
    p.account_id,
    p.player_name,
    p.hero_id,
    p.hero_name,
    p.position,
    {{ position_name('p.position') }} as position_name,
    p.is_win,
    coalesce(w.observers_placed, 0) as observers_placed,
    coalesce(w.sentries_placed, 0) as sentries_placed,
    coalesce(w.observers_before_10, 0) as observers_before_10,
    coalesce(w.sentries_before_10, 0) as sentries_before_10,
    coalesce(r.runes_taken, 0) as runes_taken,
    coalesce(r.bounty_runes, 0) as bounty_runes,
    coalesce(r.power_runes, 0) as power_runes,
    coalesce(r.water_runes, 0) as water_runes,
    coalesce(r.wisdom_runes, 0) as wisdom_runes,
    coalesce(r.double_damage_runes, 0) as double_damage_runes,
    coalesce(r.haste_runes, 0) as haste_runes,
    coalesce(r.illusion_runes, 0) as illusion_runes,
    coalesce(r.invisibility_runes, 0) as invisibility_runes,
    coalesce(r.regeneration_runes, 0) as regeneration_runes,
    coalesce(r.arcane_runes, 0) as arcane_runes,
    coalesce(r.shield_runes, 0) as shield_runes,
    coalesce(b.buybacks, 0) as buybacks,
    b.first_buyback_min,
    p.duration_min,
    p.started_at,
    p.match_date,
    p.patch_id,
    p.patch_name,
    p.league_id,
    p.league_name
from players as p
left join wards as w on w.match_id = p.match_id and w.player_slot = p.player_slot
left join runes as r on r.match_id = p.match_id and r.player_slot = p.player_slot
left join buybacks as b on b.match_id = p.match_id and b.player_slot = p.player_slot
