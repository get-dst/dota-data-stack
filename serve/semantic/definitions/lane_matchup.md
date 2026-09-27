---
metric: lane_matchup
summary: A hero against the enemy hero that stood in the same map lane in a pro match, counted on lane_matchups; its lane win rate is the share of those lanes the hero's side had won at 10 minutes.
about: lane_matchups.lane_matchup_win_rate
sql: SUM(lane_matchups.lanes_won) * 1.0 / SUM(lane_matchups.games)
aliases: [lane matchup, lane matchups, in lane against, laned against, lane opponent, lane opponents, wins the lane against, beat in lane, beats in lane, lane counter, lane counters]
---

A lane matchup is a hero and an enemy hero in the same map lane at 10 minutes: a
safe-lane hero against the off-lane heroes across from it, mid against mid. lane_name is
the hero's own lane, so "offlane heroes against Juggernaut" is lane_name 'off lane' with
opponent_hero_name 'Juggernaut'. The lane's result is the lane_outcome term and belongs to
the hero's side, so a 2v2 lane gives a hero one row per opponent with the same result.
Rank only matchups with at least 20 games (the minimum_games term) and state the game
count beside every rate; a named matchup under the floor gets its counts and the note that
the rate is withheld. Heroes on the same side are lane pairs, not matchups, and a counter
over whole matches is pro_draft_matchups on the drafts lens. Pro matches only: the public
sample carries no lane data.
