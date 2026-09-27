-- The leagues whose matches count as pro matches: those OpenDota rates premium or
-- professional. Leagues it rates excluded (its tier-3 leagues), amateur, or leaves
-- unrated are dropped here and nowhere else; stg_matches keeps only matches in a league
-- left here, so every pro model downstream sees top-tier matches only. The raw tables
-- keep every league and match.
select
    leagueid as league_id,
    {{ clean_name('name') }} as league_name,
    tier as league_tier
from {{ source('raw', 'leagues') }}
where tier in ('premium', 'professional')
