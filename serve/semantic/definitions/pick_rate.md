---
metric: pick_rate
summary: Share of pro matches in which a hero was picked by either side.
about: hero_patch_trends.patch_pick_rate
sql: SUM(hero_patch_trends.picks) * 1.0 / SUM(hero_patch_trends.matches_on_patch)
aliases: [pick %, popularity]
grain: one value per hero, over a set of matches
---

Picks of the hero divided by matches in the same window. Each match has ten picks,
so pick rates across all heroes sum to ten, not to one. On a patch it is
hero_patch_trends.patch_pick_rate (picks over the patch's matches, one row per hero and
patch); over several patches the same metric divides the hero's picks by the matches of
those patches. Over dates, count picks from hero_daily_stats.total_picks and matches from
pro_matches.match_count over the same period. Report the picks beside the rate.
