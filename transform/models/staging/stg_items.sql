-- One row per item in OpenDota's item constants. The component and ability children
-- hang off dlt's _dlt_id; they are folded into two columns here so no mart reads a
-- _dlt_ column.
with components as (
    select _dlt_parent_id, count(*) as component_count
    from {{ source('raw', 'items__components') }}
    group by 1
),

actives as (
    select distinct _dlt_parent_id
    from {{ source('raw', 'items__abilities') }}
    where type = 'active'
)

select
    i.id as item_id,
    i.name as item_key,
    i.dname as item_name,
    i.cost,
    i.qual as quality,
    i.tier as neutral_tier,
    coalesce(c.component_count, 0) as component_count,
    a._dlt_parent_id is not null as has_active_ability
from {{ source('raw', 'items') }} as i
left join components as c on c._dlt_parent_id = i._dlt_id
left join actives as a on a._dlt_parent_id = i._dlt_id
where i.id is not null
