---
metric: minimum_games
summary: A rate over fewer than 20 games is noise. The win-rate metrics return null under 20 games (10 on the thin per-position and per-player rows), so a small sample cannot top a ranking; every rate is reported with its game count.
aliases: [sample size, enough games, small sample, at least N games]
---

Win rates, matchup rates and duo rates are ratios of small integers. A hero seen in one
game has a win rate of 0 or 1, and neither means anything. The floor is built into the
metrics, not left to the reader: a hero win rate (pub_hero_stats, hero_daily_stats,
hero_patch_trends, player_performances), a matchup or duo rate (pub_matchups, pub_duos)
and a win rate by game length (pub_hero_by_duration) are null when the games behind them
are under 20, so such a row cannot rank first and shows as no rate. On the thinner rows
of professional play, one hero in one position (hero_position_meta), one player
(player_performances grouped by player) or one team (team_matches, the team_win_rate
term), the floor is 10. A question that sets its own floor keeps it. Report the game count beside every rate, and when a specific hero,
pair or player is asked about and its rate is null, say that it is under the floor and
give the count.
