-- One row per identified team per pro match: the five heroes it played, as a lineup key
-- (hero names sorted alphabetically and joined with ' / ', so the same five heroes give
-- the same key whatever the pick order), and each hero by derived position. A side
-- OpenDota did not tie to a team has no row.
with sides as (
    select
        match_id,
        is_radiant,
        team_id,
        team_name,
        bool_or(is_win) as is_win,
        string_agg(hero_name, ' / ' order by hero_name) as lineup_key,
        max(case when position = 1 then hero_name end) as carry_hero,
        max(case when position = 2 then hero_name end) as mid_hero,
        max(case when position = 3 then hero_name end) as offlane_hero,
        max(case when position = 4 then hero_name end) as soft_support_hero,
        max(case when position = 5 then hero_name end) as hard_support_hero
    from {{ ref('fact_player_match') }}
    where team_id is not null
    group by 1, 2, 3, 4
)

select
    s.match_id,
    s.is_radiant,
    case when s.is_radiant then 'radiant' else 'dire' end as side,
    s.team_id,
    s.team_name,
    case when s.is_radiant then m.dire_team_name else m.radiant_team_name end as opponent_team_name,
    s.lineup_key,
    s.carry_hero,
    s.mid_hero,
    s.offlane_hero,
    s.soft_support_hero,
    s.hard_support_hero,
    s.is_win,
    m.started_at,
    m.match_date,
    m.patch_id,
    m.patch_name,
    m.league_id,
    m.league_name
from sides as s
inner join {{ ref('fact_match') }} as m on m.match_id = s.match_id
