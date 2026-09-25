-- One row per pro match per minute: the gold and XP advantage, from the Radiant side
-- and from the eventual winner's side, so "how far behind was the winner at minute
-- 20" never needs the reader to flip a sign.
select
    a.match_id,
    a.minute,
    a.radiant_gold_adv,
    a.radiant_xp_adv,
    case when m.radiant_win then a.radiant_gold_adv else -a.radiant_gold_adv end as winner_gold_adv,
    case when m.radiant_win then a.radiant_xp_adv else -a.radiant_xp_adv end as winner_xp_adv,
    m.radiant_win,
    m.started_at,
    m.match_date,
    m.patch_id,
    m.patch_name,
    m.league_id,
    m.league_name
from {{ ref('stg_match_advantage') }} as a
inner join {{ ref('fact_match') }} as m on m.match_id = a.match_id
