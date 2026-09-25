-- Hero against hero in professional matches, per patch: games the two were picked on
-- opposite sides, and how many the first one won. The pro counterpart of pub_matchups,
-- counted from the ten player rows of every pro match (any game mode). Both orderings
-- are present, so a question can start from either hero.
select
    a.patch_id,
    a.patch_name,
    a.hero_id,
    a.hero_name,
    b.hero_id as opponent_hero_id,
    b.hero_name as opponent_hero_name,
    count(*) as games,
    sum(case when a.is_win then 1 else 0 end) as wins
from {{ ref('fact_player_match') }} as a
inner join {{ ref('fact_player_match') }} as b
    on b.match_id = a.match_id and b.is_radiant <> a.is_radiant
group by 1, 2, 3, 4, 5, 6
