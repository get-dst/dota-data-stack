---
metric: minimum_games
summary: A rate over fewer than 20 games is noise. The win-rate metrics return null under 20 games (10 on the thin per-position, per-player and per-league rows), so a small sample cannot top a ranking; every rate is reported with its game count.
aliases: [sample size, enough games, small sample, at least N games]
---

Win rates, matchup rates and duo rates are ratios of small integers. A hero seen in one
game has a win rate of 0 or 1, and neither means anything. The floor is built into the
metrics, not left to the reader. Null under 20 games: a hero win rate (pub_hero_stats,
hero_patch_trends, hero_daily_stats, player_performances), a matchup or duo rate
(pub_matchups, pub_duos, pro_draft_matchups, lane_pairings), a win rate by game length
(pub_hero_by_duration), a draft win rate (hero_draft_stats, draft_phases), an item win
rate (hero_core_items, item_timing_buckets, item_timings, hero_item_builds,
starting_items, starting_builds, final_inventories), and a team's record (team_matches,
team_lineups, team_signature_heroes, and the per-match team rates of the playstyle
tables, which count 20 matches). Null under 10: one hero in one position
(hero_position_meta, hero_playstyle), one player (player_performances grouped by player,
player_playstyle) and one team in one league (league_standings), because those rows are
thin by nature. Such a row cannot rank first and shows as no rate.

A question that sets its own floor keeps it. Report the game count beside every rate,
and when a specific hero, pair, team or player is asked about and its rate is null, say
that it is under the floor and give the count. A head-to-head between two named teams
has no floor: it is asked about one pair, so give the matches and wins beside the rate.
