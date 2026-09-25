-- Per hero per patch: how the hero fared in Captains Mode drafts. Every hero gets a row
-- on every patch that has drafts, zero-filled, so a never-drafted hero reads as 0 and
-- summing a hero's rows over several patches keeps the match denominator whole.
-- Rates are left to the reader: every count here divides by drafted_matches (or picks).
with patch_matches as (
    select patch_id, patch_name, count(distinct match_id) as drafted_matches
    from {{ ref('draft_phases') }}
    group by 1, 2
),

per_hero as (
    select
        patch_id,
        hero_id,
        sum(case when is_pick then 1 else 0 end) as picks,
        sum(case when is_ban then 1 else 0 end) as bans,
        sum(case when is_ban and draft_phase = 1 then 1 else 0 end) as first_phase_bans,
        sum(case when is_first_pick then 1 else 0 end) as first_picks,
        sum(case when is_last_pick then 1 else 0 end) as last_picks,
        sum(case when is_pick and side_won then 1 else 0 end) as wins,
        sum(case when is_pick and draft_phase = 1 then 1 else 0 end) as picks_phase_1,
        sum(case when is_pick and draft_phase = 1 and side_won then 1 else 0 end) as wins_phase_1,
        sum(case when is_pick and draft_phase = 2 then 1 else 0 end) as picks_phase_2,
        sum(case when is_pick and draft_phase = 2 and side_won then 1 else 0 end) as wins_phase_2,
        sum(case when is_pick and draft_phase = 3 then 1 else 0 end) as picks_phase_3,
        sum(case when is_pick and draft_phase = 3 and side_won then 1 else 0 end) as wins_phase_3
    from {{ ref('draft_phases') }}
    group by 1, 2
)

select
    pm.patch_id,
    pm.patch_name,
    h.hero_id,
    h.hero_name,
    pm.drafted_matches,
    coalesce(s.picks, 0) as picks,
    coalesce(s.bans, 0) as bans,
    coalesce(s.picks, 0) + coalesce(s.bans, 0) as contests,
    coalesce(s.first_phase_bans, 0) as first_phase_bans,
    coalesce(s.first_picks, 0) as first_picks,
    coalesce(s.last_picks, 0) as last_picks,
    coalesce(s.wins, 0) as wins,
    coalesce(s.picks_phase_1, 0) as picks_phase_1,
    coalesce(s.wins_phase_1, 0) as wins_phase_1,
    coalesce(s.picks_phase_2, 0) as picks_phase_2,
    coalesce(s.wins_phase_2, 0) as wins_phase_2,
    coalesce(s.picks_phase_3, 0) as picks_phase_3,
    coalesce(s.wins_phase_3, 0) as wins_phase_3
from patch_matches as pm
cross join {{ ref('dim_hero') }} as h
left join per_hero as s on s.patch_id = pm.patch_id and s.hero_id = h.hero_id
