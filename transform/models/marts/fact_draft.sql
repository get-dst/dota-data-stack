-- Picks and bans in draft order, with the side that made them and whether that
-- side went on to win.
select
    d.match_id,
    d.draft_order,
    d.is_pick,
    not d.is_pick as is_ban,
    d.hero_id,
    h.hero_name,
    d.is_radiant,
    case when d.is_radiant then m.radiant_team_id else m.dire_team_id end as team_id,
    case when d.is_radiant then m.radiant_team_name else m.dire_team_name end as team_name,
    (d.is_radiant = m.radiant_win) as side_won,
    m.started_at,
    m.match_date,
    m.patch_id,
    m.patch_name,
    m.league_id,
    m.league_name
from {{ ref('stg_picks_bans') }} as d
inner join {{ ref('fact_match') }} as m on m.match_id = d.match_id
left join {{ ref('stg_heroes') }} as h on h.hero_id = d.hero_id
