---
metric: pick_rate
summary: Share of pro matches in which a hero was picked by either side.
aliases: [pick %, popularity]
grain: one value per hero, over a set of matches
---

Picks of the hero divided by matches in the same window. Each match has ten picks,
so pick rates across all heroes sum to ten, not to one. Count picks from
hero_daily_stats.total_picks (every match has player rows; the draft log does not cover
every match) and matches from pro_matches.match_count over the same period and patch.
