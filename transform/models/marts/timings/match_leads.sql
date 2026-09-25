-- One row per pro match that has the per-minute advantage: the Radiant lead at 10, 15,
-- 20 and 25 minutes, the biggest leads each side held, and whether the game was a
-- comeback. A comeback is a match the winner won after trailing by 10 000 gold or more
-- at some minute; the same match is a throw for the side that lost that lead, so the
-- two flags describe one event from both sides and are named per team.
{% set comeback_gold = 10000 %}
with per_match as (
    select
        match_id,
        max(case when minute = 10 then radiant_gold_adv end) as radiant_gold_adv_10,
        max(case when minute = 15 then radiant_gold_adv end) as radiant_gold_adv_15,
        max(case when minute = 20 then radiant_gold_adv end) as radiant_gold_adv_20,
        max(case when minute = 25 then radiant_gold_adv end) as radiant_gold_adv_25,
        max(case when minute = 10 then radiant_xp_adv end) as radiant_xp_adv_10,
        max(case when minute = 15 then radiant_xp_adv end) as radiant_xp_adv_15,
        max(case when minute = 20 then radiant_xp_adv end) as radiant_xp_adv_20,
        max(case when minute = 25 then radiant_xp_adv end) as radiant_xp_adv_25,
        max(radiant_gold_adv) as max_radiant_gold_lead,
        -min(radiant_gold_adv) as max_dire_gold_lead
    from {{ ref('stg_match_advantage') }}
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
    m.duration_min,
    m.radiant_win,
    case when m.radiant_win then 'radiant' else 'dire' end as winner_side,
    m.radiant_team_name,
    m.dire_team_name,
    case when m.radiant_win then m.radiant_team_name else m.dire_team_name end as winner_team_name,
    case when m.radiant_win then m.dire_team_name else m.radiant_team_name end as loser_team_name,
    p.radiant_gold_adv_10,
    p.radiant_gold_adv_15,
    p.radiant_gold_adv_20,
    p.radiant_gold_adv_25,
    p.radiant_xp_adv_10,
    p.radiant_xp_adv_15,
    p.radiant_xp_adv_20,
    p.radiant_xp_adv_25,
    case when m.radiant_win then p.radiant_gold_adv_10 else -p.radiant_gold_adv_10 end as winner_gold_adv_10,
    case when m.radiant_win then p.radiant_gold_adv_15 else -p.radiant_gold_adv_15 end as winner_gold_adv_15,
    case when m.radiant_win then p.radiant_gold_adv_20 else -p.radiant_gold_adv_20 end as winner_gold_adv_20,
    case when m.radiant_win then p.radiant_gold_adv_25 else -p.radiant_gold_adv_25 end as winner_gold_adv_25,
    p.max_radiant_gold_lead,
    p.max_dire_gold_lead,
    greatest(case when m.radiant_win then p.max_dire_gold_lead else p.max_radiant_gold_lead end, 0)
        as max_winner_deficit,
    greatest(case when m.radiant_win then p.max_radiant_gold_lead else p.max_dire_gold_lead end, 0)
        as max_winner_lead,
    greatest(case when m.radiant_win then p.max_dire_gold_lead else p.max_radiant_gold_lead end, 0)
        >= {{ comeback_gold }} as is_comeback,
    case
        when greatest(case when m.radiant_win then p.max_dire_gold_lead else p.max_radiant_gold_lead end, 0)
            >= {{ comeback_gold }}
            then case when m.radiant_win then m.radiant_team_name else m.dire_team_name end
    end as comeback_team_name,
    case
        when greatest(case when m.radiant_win then p.max_dire_gold_lead else p.max_radiant_gold_lead end, 0)
            >= {{ comeback_gold }}
            then case when m.radiant_win then m.dire_team_name else m.radiant_team_name end
    end as throw_team_name,
    case
        when p.radiant_gold_adv_10 is null then null
        when p.radiant_gold_adv_10 = 0 then null
        else (p.radiant_gold_adv_10 > 0) = m.radiant_win
    end as leader_at_10_won,
    case
        when p.radiant_gold_adv_20 is null then null
        when p.radiant_gold_adv_20 = 0 then null
        else (p.radiant_gold_adv_20 > 0) = m.radiant_win
    end as leader_at_20_won
from per_match as p
inner join {{ ref('fact_match') }} as m on m.match_id = p.match_id
