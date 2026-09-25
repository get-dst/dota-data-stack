-- Per patch and first objective (first blood, first tower, first Roshan): in how many
-- pro matches a side took it, and how often that side went on to win. Matches where
-- nobody took the objective (no Roshan killed) or the log is empty are not counted.
with taken as (
    select patch_id, patch_name, 'first_blood' as objective, first_blood_side_won as taker_won
    from {{ ref('match_objectives') }}
    where first_blood_side is not null
    union all
    select patch_id, patch_name, 'first_tower', first_tower_side_won
    from {{ ref('match_objectives') }}
    where first_tower_side is not null
    union all
    select patch_id, patch_name, 'first_roshan', first_roshan_side_won
    from {{ ref('match_objectives') }}
    where first_roshan_side is not null
)

select
    patch_id,
    patch_name,
    objective,
    count(*) as matches,
    count(case when taker_won then 1 end) as taker_wins,
    count(case when taker_won then 1 end) * 1.0 / count(*) as taker_win_rate
from taken
group by 1, 2, 3
