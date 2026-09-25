-- The order pros complete their major items in: per patch and hero, which item came
-- first, second and third, how often, how those games ended, and at what minute.
-- An item's time is its first purchase in the game (the purchase log records an
-- assembled item when it completes), so a rebuy after a sell does not move it. Only
-- player-games with a purchase log count.
with first_buy as (
    select
        s.match_id,
        s.player_slot,
        i.item_id,
        i.item_key,
        min(s.bought_at_s) as first_bought_s
    from {{ ref('stg_purchases') }} as s
    inner join {{ ref('dim_item') }} as i on i.item_key = s.item_key
    where i.is_major_item
    group by 1, 2, 3, 4
),

ordered as (
    select
        match_id,
        player_slot,
        item_id,
        first_bought_s / 60.0 as bought_at_min,
        row_number() over (
            partition by match_id, player_slot order by first_bought_s, item_key
        ) as item_slot
    from first_buy
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
    o.item_slot,
    case o.item_slot when 1 then 'first' when 2 then 'second' else 'third' end as item_order,
    o.item_id,
    i.item_name,
    i.item_cost,
    count(*) as games,
    sum(case when pm.is_win then 1 else 0 end) as wins,
    percentile_cont(0.5) within group (order by o.bought_at_min) as median_bought_min,
    avg(o.bought_at_min) as avg_bought_min,
    hg.hero_games
from ordered as o
inner join {{ ref('fact_player_match') }} as pm
    on pm.match_id = o.match_id and pm.player_slot = o.player_slot
inner join {{ ref('dim_item') }} as i on i.item_id = o.item_id
inner join hero_games as hg on hg.patch_id = pm.patch_id and hg.hero_id = pm.hero_id
where o.item_slot <= 3
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 14
