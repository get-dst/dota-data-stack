-- Hero against hero, per patch and game type, over the public sample: games the
-- two were on opposite sides, and how many the first one won. Both orderings are
-- present, so a question can start from either hero.
select
    a.patch_id,
    a.patch_name,
    a.game_type,
    a.hero_id,
    a.hero_name,
    b.hero_id as opponent_hero_id,
    b.hero_name as opponent_hero_name,
    count(*) as games,
    sum(case when a.is_win then 1 else 0 end) as wins
from {{ ref('fact_pub_hero') }} as a
inner join {{ ref('fact_pub_hero') }} as b
    on b.match_id = a.match_id and b.is_radiant <> a.is_radiant
group by 1, 2, 3, 4, 5, 6, 7
