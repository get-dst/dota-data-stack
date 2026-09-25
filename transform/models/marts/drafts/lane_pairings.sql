-- Heroes that shared a lane on the same side in professional matches, per patch: games
-- together and wins. The lane is lane_role, relative to the side (1 safe lane, 2 mid,
-- 3 off lane), so a Radiant bottom pair and a Dire top pair are both safe-lane pairs.
-- Each hero carries its derived position (fact_player_match.position), so a safe-lane
-- pair reads as carry (1) with hard support (5). Players with no parsed lane, and solo
-- lanes, have no pair. Both orderings are present, so start from either hero.
select
    a.patch_id,
    a.patch_name,
    a.lane_role,
    case a.lane_role
        when 1 then 'safe lane' when 2 then 'mid' when 3 then 'off lane' when 4 then 'jungle'
    end as lane_name,
    a.hero_id,
    a.hero_name,
    a.position,
    b.hero_id as partner_hero_id,
    b.hero_name as partner_hero_name,
    b.position as partner_position,
    count(*) as games,
    sum(case when a.is_win then 1 else 0 end) as wins
from {{ ref('fact_player_match') }} as a
inner join {{ ref('fact_player_match') }} as b
    on b.match_id = a.match_id
    and b.is_radiant = a.is_radiant
    and b.lane_role = a.lane_role
    and b.player_slot <> a.player_slot
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
