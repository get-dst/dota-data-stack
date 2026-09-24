---
metric: pub_pick_rate
summary: Share of sampled public matches in which a hero was picked, at a bracket and patch.
aliases: [pub popularity, how often picked in pubs]
grain: one value per hero per bracket per patch
---

The hero's games divided by matches_in_bracket at the same bracket and patch, both on
pub_hero_stats. Each match has ten picks, so pick rates across all heroes sum to ten, not to
one. Ranked All Pick only.
