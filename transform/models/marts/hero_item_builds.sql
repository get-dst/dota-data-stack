-- Final inventories of pro players, unpivoted: per patch, hero and item, how many
-- pro games ended with the item in the six main slots and how many were won.
with slots as (
    select match_id, hero_id, hero_name, patch_id, patch_name, is_win, item_0 as item_id
    from {{ ref('fact_player_match') }}
    union all
    select match_id, hero_id, hero_name, patch_id, patch_name, is_win, item_1
    from {{ ref('fact_player_match') }}
    union all
    select match_id, hero_id, hero_name, patch_id, patch_name, is_win, item_2
    from {{ ref('fact_player_match') }}
    union all
    select match_id, hero_id, hero_name, patch_id, patch_name, is_win, item_3
    from {{ ref('fact_player_match') }}
    union all
    select match_id, hero_id, hero_name, patch_id, patch_name, is_win, item_4
    from {{ ref('fact_player_match') }}
    union all
    select match_id, hero_id, hero_name, patch_id, patch_name, is_win, item_5
    from {{ ref('fact_player_match') }}
),

hero_games as (
    select hero_id, patch_id, count(*) as hero_games
    from {{ ref('fact_player_match') }}
    group by 1, 2
)

select
    s.patch_id,
    s.patch_name,
    s.hero_id,
    s.hero_name,
    s.item_id,
    i.item_name,
    i.cost as item_cost,
    count(*) as games_with_item,
    sum(case when s.is_win then 1 else 0 end) as wins_with_item,
    hg.hero_games,
    d.is_major_item
from slots as s
inner join {{ ref('stg_items') }} as i on i.item_id = s.item_id
inner join {{ ref('dim_item') }} as d on d.item_id = s.item_id
inner join hero_games as hg on hg.hero_id = s.hero_id and hg.patch_id = s.patch_id
where s.item_id is not null and s.item_id <> 0
group by 1, 2, 3, 4, 5, 6, 7, 10, 11
