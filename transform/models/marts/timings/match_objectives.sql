-- One row per pro match: who took the first blood, the first tower and the first
-- Roshan, when, and whether that side won; plus Roshan kills and Aegis pickups per
-- side. The first tower is the first tower to fall, and the side credited with it is
-- the side that did not own it (a denied tower still counts as lost by its owner).
-- Ties at the same second go to the earlier event in the match's log. A match whose
-- objective log is empty has nulls throughout (has_objective_log = false).
with ev as (
    select
        o.*,
        row_number() over (
            partition by o.match_id, o.event_type, o.building_type
            order by o.time_s, o.event_order
        ) as nth
    from {{ ref('stg_match_objectives') }} as o
),

first_blood as (
    select match_id, time_s, actor_side
    from ev
    where event_type = 'CHAT_MESSAGE_FIRSTBLOOD' and nth = 1
),

first_tower as (
    select
        match_id,
        time_s,
        case building_side when 'radiant' then 'dire' when 'dire' then 'radiant' end as taker_side
    from ev
    where event_type = 'building_kill' and building_type = 'tower' and nth = 1
),

first_roshan as (
    select match_id, time_s, actor_side
    from ev
    where event_type = 'CHAT_MESSAGE_ROSHAN_KILL' and nth = 1
),

counts as (
    select
        match_id,
        count(*) as objective_events,
        count(case when event_type = 'CHAT_MESSAGE_ROSHAN_KILL' then 1 end) as roshan_kills,
        count(case when event_type = 'CHAT_MESSAGE_ROSHAN_KILL' and actor_side = 'radiant' then 1 end)
            as radiant_roshan_kills,
        count(case when event_type = 'CHAT_MESSAGE_ROSHAN_KILL' and actor_side = 'dire' then 1 end)
            as dire_roshan_kills,
        count(
            case
                when event_type in ('CHAT_MESSAGE_AEGIS', 'CHAT_MESSAGE_AEGIS_STOLEN') and actor_side = 'radiant'
                    then 1
            end
        ) as radiant_aegis,
        count(
            case
                when event_type in ('CHAT_MESSAGE_AEGIS', 'CHAT_MESSAGE_AEGIS_STOLEN') and actor_side = 'dire'
                    then 1
            end
        ) as dire_aegis,
        count(case when event_type = 'CHAT_MESSAGE_AEGIS_STOLEN' then 1 end) as aegis_stolen
    from ev
    group by 1
)

select
    m.match_id,
    m.started_at,
    m.match_date,
    m.patch_id,
    m.patch_name,
    m.league_id,
    m.league_name,
    m.radiant_win,
    case when m.radiant_win then 'radiant' else 'dire' end as winner_side,
    m.radiant_team_name,
    m.dire_team_name,
    c.match_id is not null as has_objective_log,
    fb.time_s as first_blood_s,
    fb.time_s / 60.0 as first_blood_min,
    fb.actor_side as first_blood_side,
    (fb.actor_side = 'radiant') = m.radiant_win as first_blood_side_won,
    ft.time_s as first_tower_s,
    ft.time_s / 60.0 as first_tower_min,
    ft.taker_side as first_tower_side,
    (ft.taker_side = 'radiant') = m.radiant_win as first_tower_side_won,
    fr.time_s as first_roshan_s,
    fr.time_s / 60.0 as first_roshan_min,
    fr.actor_side as first_roshan_side,
    (fr.actor_side = 'radiant') = m.radiant_win as first_roshan_side_won,
    c.roshan_kills,
    c.radiant_roshan_kills,
    c.dire_roshan_kills,
    c.radiant_aegis,
    c.dire_aegis,
    c.aegis_stolen
from {{ ref('fact_match') }} as m
left join counts as c on c.match_id = m.match_id
left join first_blood as fb on fb.match_id = m.match_id
left join first_tower as ft on ft.match_id = m.match_id
left join first_roshan as fr on fr.match_id = m.match_id
