---
metric: ban_rate
summary: Share of pro matches in which a hero was banned by either side.
aliases: [ban %]
grain: one value per hero, over a set of matches
---

Bans of the hero divided by matches in the same window. A hero can be banned at most
once per match. Count bans from drafts (or hero_daily_stats.total_bans) and matches
from pro_matches.match_count over the same period and patch.
