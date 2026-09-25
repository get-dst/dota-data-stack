-- Does buying an item earlier win more? Per patch, hero and major item: the games in
-- which the hero first completed the item inside each five-minute window, and how
-- many of those were won. Windows are closed at the start, open at the end: a
-- purchase at 15:00 is in 15-20.
with first_buy as (
    select
        s.match_id,
        s.player_slot,
        s.item_key,
        min(s.bought_at_min) as first_bought_min
    from {{ ref('stg_purchases') }} as s
    group by 1, 2, 3
),

bucketed as (
    select
        f.match_id,
        f.player_slot,
        i.item_id,
        i.item_name,
        i.item_cost,
        case
            when f.first_bought_min < 15 then 1
            when f.first_bought_min < 20 then 2
            when f.first_bought_min < 25 then 3
            when f.first_bought_min < 30 then 4
            else 5
        end as bucket_order
    from first_buy as f
    inner join {{ ref('dim_item') }} as i on i.item_key = f.item_key
    where i.is_major_item
)

select
    pm.patch_id,
    pm.patch_name,
    pm.hero_id,
    pm.hero_name,
    b.item_id,
    b.item_name,
    b.item_cost,
    b.bucket_order,
    case b.bucket_order
        when 1 then '<15'
        when 2 then '15-20'
        when 3 then '20-25'
        when 4 then '25-30'
        else '30+'
    end as timing_bucket,
    case b.bucket_order
        when 1 then 0
        when 2 then 15
        when 3 then 20
        when 4 then 25
        else 30
    end as bucket_start_min,
    count(*) as games,
    sum(case when pm.is_win then 1 else 0 end) as wins
from bucketed as b
inner join {{ ref('fact_player_match') }} as pm
    on pm.match_id = b.match_id and pm.player_slot = b.player_slot
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
