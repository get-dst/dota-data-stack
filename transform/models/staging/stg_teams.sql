select
    team_id,
    name as team_name,
    tag as team_tag,
    rating,
    wins as all_time_wins,
    losses as all_time_losses,
    to_timestamp(last_match_time) as last_match_at
from {{ source('raw', 'teams') }}
where name is not null and name <> ''
