-- The team grain: every pro match has exactly two rows in fact_team_match, one per
-- side, and exactly one of them is the win. Anything else double-counts a team's
-- matches or hands the match to both sides.
select match_id, count(*) as sides, sum(case when is_win then 1 else 0 end) as wins
from {{ ref('fact_team_match') }}
group by 1
having count(*) <> 2 or sum(case when is_win then 1 else 0 end) <> 1
