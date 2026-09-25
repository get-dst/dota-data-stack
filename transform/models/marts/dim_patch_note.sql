-- Patch notes, one row per line, with the hero or item resolved to its display name
-- where the subject is one.
select
    n.patch_name,
    n.section,
    n.subject,
    coalesce(h.hero_name, i.item_name, n.subject) as subject_name,
    n.heading,
    n.line_no,
    n.note
from {{ source('raw', 'patch_notes') }} as n
left join {{ ref('stg_heroes') }} as h
    on n.section = 'heroes' and h.hero_key = 'npc_dota_hero_' || n.subject
left join {{ ref('stg_items') }} as i
    on n.section = 'items' and i.item_key = n.subject
