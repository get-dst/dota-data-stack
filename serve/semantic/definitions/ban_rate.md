---
metric: ban_rate
summary: Share of pro matches in which a hero was banned by either side.
about: hero_patch_trends.patch_ban_rate
sql: SUM(hero_patch_trends.bans) * 1.0 / SUM(hero_patch_trends.matches_on_patch)
aliases: [ban %]
grain: one value per hero, over a set of matches
---

Bans of the hero divided by matches in the same window. A hero can be banned at most
once per match. On a patch it is hero_patch_trends.patch_ban_rate (bans over the patch's
matches); over dates, count bans from hero_daily_stats.total_bans and matches from
pro_matches.match_count over the same period. Report the bans beside the rate. The drafts
lens's draft_ban_rate divides by drafted Captains Mode matches instead, so the two differ
slightly.
