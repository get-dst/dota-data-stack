-- lane_matchups holds both orderings of every matchup: for each row of hero A against B
-- there is the row of B against A in the mirror lane (safe lane meets off lane, mid meets
-- mid) with the same games, and A's lanes won are B's lanes lost. A row here is a matchup
-- missing its reverse or a lane result that did not flip.
select a.patch_id, a.lane_role, a.hero_id, a.opponent_hero_id
from {{ ref('lane_matchups') }} as a
left join {{ ref('lane_matchups') }} as b
    on b.patch_id = a.patch_id
    and b.hero_id = a.opponent_hero_id
    and b.opponent_hero_id = a.hero_id
    and b.lane_role = case a.lane_role when 1 then 3 when 3 then 1 else a.lane_role end
where b.hero_id is null
    or b.games <> a.games
    or b.lanes_lost <> a.lanes_won
    or b.lanes_won <> a.lanes_lost
