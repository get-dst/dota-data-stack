-- Per hero and patch over professional matches: picks, bans, wins and the rates, next
-- to the same numbers on the previous patch (the patch before it in dim_patch's release
-- order) and the change between the two. Rates are per match on that patch: a hero is
-- picked at most once per match, so pick rate = picks / matches. The previous-patch
-- columns are null when the loaded window holds no match of the previous patch. Every
-- hero has a row on every patch of the window, zero when nobody picked or banned it
-- there, so a pick rate summed over several patches counts every patch's matches.
with patches as (
    select
        p.patch_id,
        p.patch_name,
        p.patch_started_at,
        p.is_current,
        lag(p.patch_id) over (order by p.patch_started_at) as previous_patch_id,
        lag(p.patch_name) over (order by p.patch_started_at) as previous_patch_name
    from {{ ref('dim_patch') }} as p
),

matches as (
    select patch_id, count(*) as matches
    from {{ ref('fact_match') }}
    group by 1
),

picks as (
    select
        patch_id,
        hero_id,
        count(*) as picks,
        count(case when is_win then 1 end) as wins
    from {{ ref('fact_player_match') }}
    group by 1, 2
),

bans as (
    select patch_id, hero_id, count(*) as bans
    from {{ ref('fact_draft') }}
    where is_ban
    group by 1, 2
),

hero_patch as (
    select
        mt.patch_id,
        h.hero_id,
        coalesce(pk.picks, 0) as picks,
        coalesce(pk.wins, 0) as wins,
        coalesce(b.bans, 0) as bans
    from matches as mt
    cross join {{ ref('dim_hero') }} as h
    left join picks as pk on pk.patch_id = mt.patch_id and pk.hero_id = h.hero_id
    left join bans as b on b.patch_id = mt.patch_id and b.hero_id = h.hero_id
),

rated as (
    select
        hp.patch_id,
        hp.hero_id,
        mt.matches,
        hp.picks,
        hp.bans,
        hp.wins,
        hp.picks - hp.wins as losses,
        case when hp.picks > 0 then hp.wins * 1.0 / hp.picks end as win_rate,
        hp.picks * 1.0 / mt.matches as pick_rate,
        hp.bans * 1.0 / mt.matches as ban_rate
    from hero_patch as hp
    inner join matches as mt on mt.patch_id = hp.patch_id
)

select
    p.patch_id,
    p.patch_name,
    p.patch_started_at,
    p.is_current as is_current_patch,
    r.hero_id,
    h.hero_name,
    r.matches as matches_on_patch,
    r.picks,
    r.bans,
    r.wins,
    r.losses,
    r.win_rate,
    r.pick_rate,
    r.ban_rate,
    p.previous_patch_id,
    p.previous_patch_name,
    pm.matches as previous_matches,
    case when pm.matches is not null then coalesce(pr.picks, 0) end as previous_picks,
    case when pm.matches is not null then coalesce(pr.bans, 0) end as previous_bans,
    pr.win_rate as previous_win_rate,
    case when pm.matches is not null then coalesce(pr.pick_rate, 0) end as previous_pick_rate,
    case when pm.matches is not null then coalesce(pr.ban_rate, 0) end as previous_ban_rate,
    r.win_rate - pr.win_rate as win_rate_change,
    r.pick_rate - case when pm.matches is not null then coalesce(pr.pick_rate, 0) end as pick_rate_change,
    r.ban_rate - case when pm.matches is not null then coalesce(pr.ban_rate, 0) end as ban_rate_change
from rated as r
inner join patches as p on p.patch_id = r.patch_id
left join {{ ref('dim_hero') }} as h on h.hero_id = r.hero_id
left join matches as pm on pm.patch_id = p.previous_patch_id
left join rated as pr on pr.patch_id = p.previous_patch_id and pr.hero_id = r.hero_id
