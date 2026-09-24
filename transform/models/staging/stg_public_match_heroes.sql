-- Ten rows per public match: the hero, the side, and whether that side won.
with sides as (
    select _dlt_parent_id, value as hero_id, true as is_radiant
    from {{ source('raw', 'public_matches__radiant_team') }}
    union all
    select _dlt_parent_id, value as hero_id, false as is_radiant
    from {{ source('raw', 'public_matches__dire_team') }}
)

select
    m.match_id,
    s.hero_id,
    s.is_radiant,
    (s.is_radiant = m.radiant_win) as is_win
from sides as s
inner join {{ ref('stg_public_matches') }} as m on m._dlt_id = s._dlt_parent_id
