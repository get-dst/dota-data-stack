-- The current patch is the one with no end: a declared fact the serving layer can
-- name, never something to guess from match dates.
select
    patch_id,
    patch_name,
    patch_started_at,
    patch_ended_at,
    patch_ended_at is null as is_current
from {{ ref('stg_patches') }}
