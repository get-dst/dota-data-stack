-- A patch is a window: it starts on its release date and ends when the next one lands.
select
    id as patch_id,
    name as patch_name,
    date as patch_started_at,
    lead(date) over (order by date) as patch_ended_at
from {{ source('raw', 'patches') }}
