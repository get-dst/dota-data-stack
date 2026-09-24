-- One row per hero per sampled public match: the grain every pub meta number is
-- counted at.
select
    h.match_id,
    h.hero_id,
    d.hero_name,
    h.is_radiant,
    h.is_win,
    m.match_date,
    m.started_at,
    m.patch_id,
    m.patch_name,
    m.bracket_id,
    m.bracket_name,
    m.game_type,
    m.duration_min
from {{ ref('stg_public_match_heroes') }} as h
inner join {{ ref('fact_pub_match') }} as m on m.match_id = h.match_id
left join {{ ref('stg_heroes') }} as d on d.hero_id = h.hero_id
