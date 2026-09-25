-- One row per player per parsed pro match: a declared proxy for "space created", in two
-- parts that are kept apart because they measure different things (the space_created
-- definition in serve/ says what each can and cannot show).
--
-- Attention absorbed: damage the hero took from enemy heroes, per game minute. Only the
--   five enemy heroes' keys count, so self-damage (Centaur's Double Edge), creeps, towers
--   and Roshan do not; illusions and summons are keyed by their own unit, not the hero,
--   and are not counted either.
-- Trade deaths: the hero's deaths to an enemy hero after which the hero's side took an
--   enemy tower or killed Roshan within 60 seconds. A death is timed from the enemy
--   killer's kills log; deaths to creeps, towers or Roshan have no time and are not in
--   either count.
with players as (
    select pm.*, h.hero_key
    from {{ ref('fact_player_match') }} as pm
    inner join {{ ref('stg_heroes') }} as h on h.hero_id = pm.hero_id
    where pm.match_id in (select match_id from {{ ref('stg_player_minutes') }})
),

enemy_damage as (
    select
        p.match_id,
        p.player_slot,
        sum(d.amount) as enemy_hero_damage_taken
    from players as p
    inner join {{ ref('stg_player_damage_taken') }} as d
        on d.match_id = p.match_id and d.player_slot = p.player_slot
    inner join players as e
        on e.match_id = p.match_id and e.is_radiant <> p.is_radiant and e.hero_key = d.source_key
    group by 1, 2
),

deaths as (
    select
        p.match_id,
        p.player_slot,
        p.is_radiant,
        k.time_s
    from players as p
    inner join {{ ref('stg_player_hero_kills') }} as k
        on k.match_id = p.match_id and k.victim_hero_key = p.hero_key
    -- the killer is an enemy (a deny by an ally is not a hero kill in the log, but be sure)
    where (k.killer_slot < 128) <> p.is_radiant
),

side_objectives as (
    select
        match_id,
        time_s,
        case
            when event_type = 'building_kill' and building_type = 'tower'
                then case building_side when 'radiant' then false when 'dire' then true end
            when event_type = 'CHAT_MESSAGE_ROSHAN_KILL'
                then actor_side = 'radiant'
        end as taken_by_radiant
    from {{ ref('stg_match_objectives') }}
    where (event_type = 'building_kill' and building_type = 'tower')
       or event_type = 'CHAT_MESSAGE_ROSHAN_KILL'
),

trades as (
    select
        d.match_id,
        d.player_slot,
        count(*) as hero_kill_deaths,
        count(case when exists (
            select 1
            from side_objectives as o
            where o.match_id = d.match_id
              and o.taken_by_radiant = d.is_radiant
              and o.time_s > d.time_s
              and o.time_s <= d.time_s + 60
        ) then 1 end) as trade_deaths
    from deaths as d
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
    p.is_win,
    p.duration_min,
    coalesce(ed.enemy_hero_damage_taken, 0) as enemy_hero_damage_taken,
    coalesce(ed.enemy_hero_damage_taken, 0) / nullif(p.duration_min, 0) as enemy_hero_damage_taken_per_min,
    p.deaths as total_deaths,
    coalesce(t.hero_kill_deaths, 0) as hero_kill_deaths,
    coalesce(t.trade_deaths, 0) as trade_deaths,
    t.trade_deaths * 1.0 / nullif(t.hero_kill_deaths, 0) as trade_death_share,
    p.started_at,
    p.match_date,
    p.patch_id,
    p.patch_name,
    p.league_id,
    p.league_name
from players as p
left join enemy_damage as ed on ed.match_id = p.match_id and ed.player_slot = p.player_slot
left join trades as t on t.match_id = p.match_id and t.player_slot = p.player_slot
