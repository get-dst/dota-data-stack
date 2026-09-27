-- Hero against the enemy heroes in the same map lane in parsed professional matches, per
-- patch: the lanes the two played against each other, how they stood at 10 minutes and
-- how many of those matches the hero's side won. Built from lane_outcomes, so a lane
-- counts only when it has a result, and its result belongs to the hero's side. A 2v2
-- lane gives a hero one row per opponent. lane_role is the hero's own, relative to its
-- side (1 safe lane, 2 mid, 3 off lane); the opponent's is the mirror, so a safe-lane
-- hero's row meets an off-lane hero and the reverse row carries lane_role 3. Both
-- orderings are present, so start from either hero. Counts only: a rate's games floor
-- lives in the serving layer.
select
    a.patch_id,
    a.patch_name,
    a.lane_role,
    case a.lane_role
        when 1 then 'safe lane' when 2 then 'mid' when 3 then 'off lane'
    end as lane_name,
    a.hero_id,
    a.hero_name,
    b.hero_id as opponent_hero_id,
    b.hero_name as opponent_hero_name,
    count(*) as games,
    count(case when a.lane_result = 'won' then 1 end) as lanes_won,
    count(case when a.lane_result = 'drawn' then 1 end) as lanes_drawn,
    count(case when a.lane_result = 'lost' then 1 end) as lanes_lost,
    count(case when a.is_win then 1 end) as wins
from {{ ref('lane_outcomes') }} as a
inner join {{ ref('lane_outcomes') }} as b
    on b.match_id = a.match_id
    and b.lane = a.lane
    and b.is_radiant <> a.is_radiant
group by 1, 2, 3, 4, 5, 6, 7, 8
