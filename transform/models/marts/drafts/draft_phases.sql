-- Every pick and ban of a Captains Mode pro match, with its draft phase and its place
-- among the picks. On these patches the Captains Mode draft runs in six blocks: 7 bans,
-- 2 picks, 3 bans, 6 picks, 4 bans, 2 picks (24 actions; 5 picks and 7 bans per side).
-- The phase is read from the runs of consecutive bans or picks, not from draft_order:
-- when a ban is skipped the draft has 23 actions and every later order shifts down by
-- one, so a fixed order-to-phase map would misplace the tail of that draft.
-- Other game modes (a pro match played in All Pick, for instance) have no phases and
-- are left out.
with captains_mode as (
    select
        d.*,
        m.radiant_team_name,
        m.dire_team_name,
        lag(d.is_pick) over (partition by d.match_id order by d.draft_order) as prev_is_pick
    from {{ ref('fact_draft') }} as d
    inner join {{ ref('fact_match') }} as m on m.match_id = d.match_id
    where m.game_mode_id = 2  -- Captains Mode
),

runs as (
    select
        *,
        1 + sum(case when is_pick <> prev_is_pick then 1 else 0 end) over (
            partition by match_id order by draft_order rows unbounded preceding
        ) as run_number
    from captains_mode
),

numbered as (
    select
        *,
        case when is_pick then row_number() over (
            partition by match_id, is_pick order by draft_order
        ) end as match_pick_number,
        case when is_pick then row_number() over (
            partition by match_id, is_radiant, is_pick order by draft_order
        ) end as team_pick_number,
        case when is_ban then row_number() over (
            partition by match_id, is_ban order by draft_order
        ) end as match_ban_number,
        count(case when is_pick then 1 end) over (partition by match_id) as picks_in_match
    from runs
),

first_pick_side as (
    select match_id, is_radiant as first_pick_is_radiant
    from numbered
    where match_pick_number = 1
)

select
    n.match_id,
    n.draft_order,
    case when is_pick then 'pick' else 'ban' end as action,
    is_pick,
    is_ban,
    -- runs 1-2 are phase 1, 3-4 phase 2, 5-6 phase 3; a seventh run would be a draft of
    -- another shape and gets no phase (tests/drafts/draft_phase_shape.sql fails on it).
    case when run_number <= 2 then 1 when run_number <= 4 then 2 when run_number <= 6 then 3 end
        as draft_phase,
    case when run_number <= 6 then
        case when is_pick then 'pick' else 'ban' end || ' phase '
        || case when run_number <= 2 then '1' when run_number <= 4 then '2' else '3' end
    end as phase_name,
    cast(match_pick_number as integer) as match_pick_number,
    cast(team_pick_number as integer) as team_pick_number,
    cast(match_ban_number as integer) as match_ban_number,
    coalesce(match_pick_number = 1, false) as is_first_pick,
    coalesce(match_pick_number = picks_in_match, false) as is_last_pick,
    n.is_radiant = f.first_pick_is_radiant as is_first_pick_side,
    hero_id,
    hero_name,
    n.is_radiant,
    case when n.is_radiant then 'radiant' else 'dire' end as side,
    team_id,
    team_name,
    case when n.is_radiant then dire_team_name else radiant_team_name end as opponent_team_name,
    side_won,
    started_at,
    match_date,
    patch_id,
    patch_name,
    league_id,
    league_name
from numbered as n
inner join first_pick_side as f on f.match_id = n.match_id
