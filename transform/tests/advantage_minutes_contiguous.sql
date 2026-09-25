-- The per-minute advantage of a match starts at the horn and has no gaps: minutes
-- 0..n, n + 1 rows. A gap would make "the lead at minute 20" silently missing.
select match_id, min(minute) as first_minute, max(minute) as last_minute, count(*) as minutes
from {{ ref('gold_advantage_timeline') }}
group by 1
having min(minute) <> 0 or max(minute) + 1 <> count(*)
