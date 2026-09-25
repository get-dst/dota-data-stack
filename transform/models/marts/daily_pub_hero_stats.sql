-- Hero games and wins per day over the public sample, ranked All Pick only, so a
-- trend question ("is Pudge rising this week?") reads a day series, not the hero grain.
select
    match_date,
    patch_id,
    patch_name,
    hero_id,
    hero_name,
    count(*) as games,
    sum(case when is_win then 1 else 0 end) as wins
from {{ ref('fact_pub_hero') }}
where game_type = 'ranked_all_pick'
group by 1, 2, 3, 4, 5
