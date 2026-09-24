select
    h.id as hero_id,
    h.localized_name as hero_name,
    h.name as hero_key,
    h.primary_attr as primary_attribute,
    h.attack_type,
    (
        select string_agg(r.value, ', ' order by r._dlt_list_idx)
        from {{ source('raw', 'heroes__roles') }} as r
        where r._dlt_parent_id = h._dlt_id
    ) as roles
from {{ source('raw', 'heroes') }} as h
