-- Per hero, patch and position (1-5, the derived position in fact_player_match) over
-- professional matches: games, the share of the hero's positioned games on that patch
-- played in that position, and the win rate there. Player-games without a derived
-- position (roaming or unparsed lanes) are left out of both counts.
with games as (
    select
        patch_id,
        patch_name,
        hero_id,
        hero_name,
        position,
        count(*) as games,
        count(case when is_win then 1 end) as wins
    from {{ ref('fact_player_match') }}
    where position is not null
    group by 1, 2, 3, 4, 5
)

select
    patch_id,
    patch_name,
    hero_id,
    hero_name,
    position,
    games,
    wins,
    games - wins as losses,
    wins * 1.0 / games as win_rate,
    sum(games) over (partition by patch_id, hero_id) as hero_games,
    games * 1.0 / sum(games) over (partition by patch_id, hero_id) as position_share
from games
