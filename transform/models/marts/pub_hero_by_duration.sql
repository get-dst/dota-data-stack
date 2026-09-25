-- Hero win rate by how long the game went, over the public sample (ranked All Pick):
-- the "does Anti-Mage win the long games?" table.
select
    patch_id,
    patch_name,
    hero_id,
    hero_name,
    case
        when duration_min < 25 then 'under 25 min'
        when duration_min < 35 then '25-35 min'
        when duration_min < 45 then '35-45 min'
        else '45 min and over'
    end as duration_bucket,
    case
        when duration_min < 25 then 1
        when duration_min < 35 then 2
        when duration_min < 45 then 3
        else 4
    end as duration_bucket_order,
    count(*) as games,
    sum(case when is_win then 1 else 0 end) as wins
from {{ ref('fact_pub_hero') }}
where game_type = 'ranked_all_pick'
group by 1, 2, 3, 4, 5, 6
