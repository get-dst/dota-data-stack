select league_id, league_name, league_tier
from {{ ref('stg_leagues') }}
