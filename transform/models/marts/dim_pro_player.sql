select account_id, player_name, persona_name, team_id, team_name, team_tag, country_code, last_match_at
from {{ ref('stg_pro_players') }}
