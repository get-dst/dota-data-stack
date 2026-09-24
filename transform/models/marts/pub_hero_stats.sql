-- Hero games and wins per patch, bracket and game type over the public sample.
-- Pick rate needs the match count at the same grain, carried on every row.
with games as (
    select
        patch_id, patch_name, bracket_id, bracket_name, game_type, hero_id, hero_name,
        count(*) as games,
        sum(case when is_win then 1 else 0 end) as wins
    from {{ ref('fact_pub_hero') }}
    group by 1, 2, 3, 4, 5, 6, 7
),

matches as (
    select patch_id, bracket_id, game_type, count(*) as matches
    from {{ ref('fact_pub_match') }}
    group by 1, 2, 3
)

select
    g.patch_id,
    g.patch_name,
    g.bracket_id,
    g.bracket_name,
    g.game_type,
    g.hero_id,
    g.hero_name,
    g.games,
    g.wins,
    g.games - g.wins as losses,
    m.matches as matches_in_bracket
from games as g
left join matches as m
    on m.patch_id = g.patch_id and m.bracket_id = g.bracket_id and m.game_type = g.game_type
