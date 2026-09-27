---
metric: last_pick
summary: The tenth and final hero picked in a Captains Mode draft, chosen knowing the other nine.
about: hero_draft_stats.last_pick_rate
sql: SUM(hero_draft_stats.last_picks) * 1.0 / SUM(hero_draft_stats.drafted_matches)
aliases: [last-pick, last picked, final pick, last pick slot]
---

The last pick is the match's final pick: exactly one per drafted match, made after both
sides' other picks are known, which is why counter heroes gather there. A last-pick rate
is last picks of the hero divided by drafted matches (hero_draft_stats.last_pick_rate).
Pick phase 3 holds the last two picks, one per side; "last pick" is only the tenth.
