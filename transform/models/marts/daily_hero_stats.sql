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
)

select
    p.match_date,
    p.patch_id,
    p.patch_name,
    p.hero_id,
    p.hero_name,
    p.picks,
    coalesce(b.bans, 0) as bans,
    p.wins,
    p.picks - p.wins as losses,
    mt.matches as matches_that_day
from picks as p
left join bans as b on b.match_date = p.match_date and b.patch_id = p.patch_id and b.hero_id = p.hero_id
left join matches as mt on mt.match_date = p.match_date and mt.patch_id = p.patch_id
