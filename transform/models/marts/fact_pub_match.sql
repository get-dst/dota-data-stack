-- One row per sampled public match, with the patch it was played on resolved from
-- the patch windows (the public feed carries no patch id) and the bracket named.
select
    m.match_id,
    m.started_at,
    m.match_date,
    m.duration_s,
    m.duration_min,
    m.radiant_win,
    m.avg_rank_tier,
    m.bracket_id,
    b.bracket_name,
    m.game_type,
    m.game_mode_id,
    m.lobby_type_id,
    p.patch_id,
    p.patch_name
from {{ ref('stg_public_matches') }} as m
left join {{ ref('dim_bracket') }} as b on b.bracket_id = m.bracket_id
left join {{ ref('stg_patches') }} as p
    on m.started_at >= p.patch_started_at
    and (p.patch_ended_at is null or m.started_at < p.patch_ended_at)
