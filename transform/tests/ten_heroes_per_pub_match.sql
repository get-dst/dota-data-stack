-- A public match carries exactly ten hero rows; fewer is a half-loaded row.
select match_id, count(*) as heroes
from {{ ref('fact_pub_hero') }}
group by 1
having count(*) <> 10
