---
metric: pub_pick_rate
summary: Share of sampled public matches in which a hero was picked, at a bracket and patch.
about: pub_hero_stats.pub_pick_rate
sql: SUM(pub_hero_stats.games) * 1.0 / SUM(pub_hero_stats.matches_in_bracket)
aliases: [pub popularity, how often picked in pubs]
grain: one value per hero per bracket per patch
---

The hero's games divided by the sampled matches at the same bracket and patch, both on
pub_hero_stats (the pub_pick_rate metric, grouped or filtered by hero). Each match has ten
picks, so pick rates across all heroes sum to ten, not to one. Ranked All Pick only, and
a sample, not every game; report the games beside the rate.
