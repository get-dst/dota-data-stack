-- Whole starting builds: every pre-game purchase (at or before 0:00) of one player in
-- one game, written as one line in item-name order with counts, e.g.
-- "Iron Branch x2, Tango, Quelling Blade" — then counted per patch and hero. Only
-- player-games with a purchase log and at least one pre-game purchase count.
with pre_game as (
    select s.match_id, s.player_slot, i.item_name, count(*) as units
    from {{ ref('stg_purchases') }} as s
    inner join {{ ref('dim_item') }} as i on i.item_key = s.item_key
    where s.bought_at_s <= 0
    group by 1, 2, 3
),

builds as (
    select
        match_id,
        player_slot,
        string_agg(
            case when units > 1 then item_name || ' x' || cast(units as varchar) else item_name end,
            ', ' order by item_name
        ) as starting_build,
        sum(units) as build_items
    from pre_game
    group by 1, 2
)

select
    pm.patch_id,
    pm.patch_name,
    pm.hero_id,
    pm.hero_name,
    b.starting_build,
    b.build_items,
    count(*) as games,
    sum(case when pm.is_win then 1 else 0 end) as wins
from builds as b
inner join {{ ref('fact_player_match') }} as pm
    on pm.match_id = b.match_id and pm.player_slot = b.player_slot
group by 1, 2, 3, 4, 5, 6
