-- The public-match sample: one row per public matchmaking game the loader saw.
-- Game type is decided here, once: ranked All Pick is the meta people mean;
-- Turbo is a different game and must never blend into it. Modes that are not a
-- ten-hero draft (1v1 mid, ability draft, events) are dropped, and so is any row
-- whose hero lists came back incomplete or with a hero twice.
with complete as (
    select s._dlt_parent_id
    from (
        select _dlt_parent_id, value from {{ source('raw', 'public_matches__radiant_team') }}
        union all
        select _dlt_parent_id, value from {{ source('raw', 'public_matches__dire_team') }}
    ) as s
    group by s._dlt_parent_id
    having count(*) = 10 and count(distinct s.value) = 10
)

select
    m.match_id,
    to_timestamp(m.start_time) as started_at,
    cast(to_timestamp(m.start_time) as date) as match_date,
    m.duration as duration_s,
    m.duration / 60.0 as duration_min,
    m.radiant_win,
    m.avg_rank_tier,
    cast(floor(m.avg_rank_tier / 10) as integer) as bracket_id,
    m.game_mode as game_mode_id,
    m.lobby_type as lobby_type_id,
    case
        when m.game_mode = 23 then 'turbo'
        when m.game_mode = 22 and m.lobby_type = 7 then 'ranked_all_pick'
        else 'unranked_all_pick'
    end as game_type,
    m.cluster as cluster_id,
    m._dlt_id
from {{ source('raw', 'public_matches') }} as m
inner join complete as c on c._dlt_parent_id = m._dlt_id
where m.game_mode in (1, 22, 23)
