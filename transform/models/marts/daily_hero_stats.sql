-- Per day, per hero, per patch: how often picked, banned, and won. The rollup the
-- common questions read, so they never scan the player grain.
with picks as (
    select
        match_date,
        patch_id,
        patch_name,
        hero_id,
        hero_name,
        count(*) as picks,
        sum(case when is_win then 1 else 0 end) as wins
    from {{ ref('fact_player_match') }}
    group by 1, 2, 3, 4, 5
),

bans as (
    select match_date, patch_id, hero_id, count(*) as bans
    from {{ ref('fact_draft') }}
    where is_ban
    group by 1, 2, 3
),

matches as (
    select match_date, patch_id, count(*) as matches
    from {{ ref('fact_match') }}
    group by 1, 2
),

-- Every (day, patch, hero) that was picked OR banned: a hero banned on a day it
-- was never picked still counts its bans (driving from picks alone dropped them).
keys as (
    select match_date, patch_id, hero_id from picks
    union
    select match_date, patch_id, hero_id from bans
)

select
    k.match_date,
    k.patch_id,
    dp.patch_name,
    k.hero_id,
    dh.hero_name,
    coalesce(p.picks, 0) as picks,
    coalesce(b.bans, 0) as bans,
    coalesce(p.wins, 0) as wins,
    coalesce(p.picks, 0) - coalesce(p.wins, 0) as losses,
    mt.matches as matches_that_day
from keys as k
left join picks as p on p.match_date = k.match_date and p.patch_id = k.patch_id and p.hero_id = k.hero_id
left join bans as b on b.match_date = k.match_date and b.patch_id = k.patch_id and b.hero_id = k.hero_id
left join matches as mt on mt.match_date = k.match_date and mt.patch_id = k.patch_id
left join {{ ref('dim_patch') }} as dp on dp.patch_id = k.patch_id
left join {{ ref('dim_hero') }} as dh on dh.hero_id = k.hero_id
