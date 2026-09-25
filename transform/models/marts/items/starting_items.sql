-- What pros walk out of the fountain with: purchases at or before 0:00 on the game
-- clock (the pre-game shop), per patch, hero and item. The free starting Town Portal
-- Scroll is not a purchase and is not here. Only player-games with a purchase log
-- count.
with pre_game as (
    select match_id, player_slot, item_key, count(*) as units
    from {{ ref('stg_purchases') }}
    where bought_at_s <= 0
    group by 1, 2, 3
),

logged as (
    select distinct match_id, player_slot from {{ ref('stg_purchases') }}
),

hero_games as (
    select pm.patch_id, pm.hero_id, count(*) as hero_games
    from {{ ref('fact_player_match') }} as pm
    inner join logged as l on l.match_id = pm.match_id and l.player_slot = pm.player_slot
    group by 1, 2
)

select
    pm.patch_id,
    pm.patch_name,
    pm.hero_id,
    pm.hero_name,
    i.item_id,
    i.item_name,
    i.item_cost,
    count(*) as games_bought,
    sum(g.units) as units_bought,
    sum(case when pm.is_win then 1 else 0 end) as wins_when_bought,
    hg.hero_games
from pre_game as g
inner join {{ ref('fact_player_match') }} as pm
    on pm.match_id = g.match_id and pm.player_slot = g.player_slot
inner join {{ ref('dim_item') }} as i on i.item_key = g.item_key
inner join hero_games as hg on hg.patch_id = pm.patch_id and hg.hero_id = pm.hero_id
group by 1, 2, 3, 4, 5, 6, 7, 11
