-- When pros first buy an item on a hero, per patch: the typical minute and how many
-- games bought it at all. First purchase per player-game, so a Blink rebuy after a
-- sell does not count twice.
with first_buy as (
    select
        s.match_id,
        s.player_slot,
        s.hero_id,
        s.item_key,
        min(s.bought_at_min) as first_bought_min
    from {{ ref('stg_purchases') }} as s
    where s.bought_at_s >= 0
    group by 1, 2, 3, 4
),

joined as (
    select
        f.match_id,
        f.hero_id,
        pm.hero_name,
        pm.patch_id,
        pm.patch_name,
        pm.is_win,
        i.item_id,
        i.item_name,
        i.cost as item_cost,
        f.first_bought_min
    from first_buy as f
    inner join {{ ref('fact_player_match') }} as pm
        on pm.match_id = f.match_id and pm.player_slot = f.player_slot
    inner join {{ ref('stg_items') }} as i on i.item_key = f.item_key
    where i.cost >= 1000
)

select
    patch_id,
    patch_name,
    hero_id,
    hero_name,
    item_id,
    item_name,
    item_cost,
    count(*) as games_bought,
    sum(case when is_win then 1 else 0 end) as wins_when_bought,
    avg(first_bought_min) as avg_first_bought_min,
    min(first_bought_min) as earliest_bought_min
from joined
group by 1, 2, 3, 4, 5, 6, 7
