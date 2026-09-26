-- Every item purchase in every pro match: when (seconds from the horn, negative in the
-- pre-game), by whom, and what. Consumables and components stay; the marts choose.
select
    m.match_id,
    p.player_slot,
    p.hero_id,
    pl.time as bought_at_s,
    pl.time / 60.0 as bought_at_min,
    pl.key as item_key
from {{ source('raw', 'match_details__players__purchase_log') }} as pl
inner join {{ source('raw', 'match_details__players') }} as p on p._dlt_id = pl._dlt_parent_id
inner join {{ ref('stg_matches') }} as m on m._dlt_id = p._dlt_parent_id
