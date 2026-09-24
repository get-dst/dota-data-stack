select
    leagueid as league_id,
    name as league_name,
    tier as league_tier
from {{ source('raw', 'leagues') }}
