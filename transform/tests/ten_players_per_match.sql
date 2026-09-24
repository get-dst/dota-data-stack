-- A pro match has exactly ten player rows. Anything else is a half-loaded match.
select match_id, count(*) as players
from {{ ref('fact_player_match') }}
group by 1
having count(*) <> 10
