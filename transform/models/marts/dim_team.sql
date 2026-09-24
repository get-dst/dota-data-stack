select team_id, team_name, team_tag, rating, all_time_wins, all_time_losses, last_match_at
from {{ ref('stg_teams') }}
