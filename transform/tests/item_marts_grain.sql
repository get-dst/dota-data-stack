-- The item marts' grains: any key appearing twice is a fan-out in the joins.
select 'hero_core_items' as model, count(*) as dupes
from {{ ref('hero_core_items') }}
group by patch_id, hero_id, item_slot, item_id
having count(*) > 1
union all
select 'item_timing_buckets', count(*)
from {{ ref('item_timing_buckets') }}
group by patch_id, hero_id, item_id, bucket_order
having count(*) > 1
union all
select 'starting_items', count(*)
from {{ ref('starting_items') }}
group by patch_id, hero_id, item_id
having count(*) > 1
union all
select 'starting_builds', count(*)
from {{ ref('starting_builds') }}
group by patch_id, hero_id, starting_build
having count(*) > 1
union all
select 'final_inventories', count(*)
from {{ ref('final_inventories') }}
group by patch_id, hero_id, slot_group, item_id
having count(*) > 1
