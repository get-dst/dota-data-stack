-- Names and tags are trimmed (clean_name); a team whose name is blank is dropped.
select
    team_id,
    {{ clean_name('name') }} as team_name,
    {{ clean_name('tag') }} as team_tag,
    rating,
    wins as all_time_wins,
    losses as all_time_losses,
    to_timestamp(last_match_time) as last_match_at
from {{ source('raw', 'teams') }}
where {{ clean_name('name') }} is not null
