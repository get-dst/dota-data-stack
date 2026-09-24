-- Hero with hero on the same side, per patch and game type, over the public sample.
-- Both orderings are present, so a question can start from either hero.
select
    a.patch_id,
    a.patch_name,
    a.game_type,
    a.hero_id,
    a.hero_name,
    b.hero_id as ally_hero_id,
    b.hero_name as ally_hero_name,
    count(*) as games,
    sum(case when a.is_win then 1 else 0 end) as wins
from {{ ref('fact_pub_hero') }} as a
inner join {{ ref('fact_pub_hero') }} as b
    on b.match_id = a.match_id and b.is_radiant = a.is_radiant and b.hero_id <> a.hero_id
group by 1, 2, 3, 4, 5, 6, 7
