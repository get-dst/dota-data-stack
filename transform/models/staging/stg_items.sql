select
    id as item_id,
    name as item_key,
    dname as item_name,
    cost,
    qual as quality,
    tier as neutral_tier
from {{ source('raw', 'items') }}
where id is not null
