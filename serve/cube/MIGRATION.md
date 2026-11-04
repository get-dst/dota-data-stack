# Migration report: dst catalogue -> Cube model

Written by `dst migrate-model`. The model is generated once and then authored: a re-run refuses to overwrite a file edited since.

## Census

| item | n |
|---|---:|
| dst entities | 47 |
| dst relationships | 103 |
| dst metrics | 322 |
| dst fields | 743 |
| dst definitions | 36 |
| dst lenses | 6 |
| dst blueprints | 0 |
| cube cubes | 47 |
| cube cubes with population baked | 4 |
| cube cubes with sql | 4 |
| cube definitions as segments | 23 |
| cube definitions in overlay (prose) | 13 |
| cube dimensions | 743 |
| cube dimensions renamed (name shared with a measure) | 25 |
| cube dimensions with a dictionary | 81 |
| cube fact view joins past one hop | 6 |
| cube fact views (joined dimensions) | 41 |
| cube joins | 103 |
| cube measures | 322 |
| cube measures avg | 24 |
| cube measures count | 23 |
| cube measures count_distinct | 7 |
| cube measures derived (number) | 78 |
| cube measures max | 5 |
| cube measures min | 1 |
| cube measures ratio (number) | 23 |
| cube measures sum | 161 |
| cube segments | 20 |
| cube time dimensions | 35 |
| cube views | 6 |

## Carried outside the Cube model

| where | item | how it is carried | failure mode |
|---|---|---|---|
| hero_playstyle | field games shares its name with a metric | dimension renamed games_value (one namespace per cube) | not_declared |
| hero_playstyle | field wins shares its name with a metric | dimension renamed wins_value (one namespace per cube) | not_declared |
| hero_playstyle | field game_minutes shares its name with a metric | dimension renamed game_minutes_value (one namespace per cube) | not_declared |
| hero_playstyle | field match_fights shares its name with a metric | dimension renamed match_fights_value (one namespace per cube) | not_declared |
| hero_playstyle | field fights_present shares its name with a metric | dimension renamed fights_present_value (one namespace per cube) | not_declared |
| hero_playstyle | field fight_deaths shares its name with a metric | dimension renamed fight_deaths_value (one namespace per cube) | not_declared |
| hero_playstyle | field deaths_outside_fights shares its name with a metric | dimension renamed deaths_outside_fights_value (one namespace per cube) | not_declared |
| hero_playstyle | field fight_gold_delta shares its name with a metric | dimension renamed fight_gold_delta_value (one namespace per cube) | not_declared |
| hero_playstyle | field farm_games_10 shares its name with a metric | dimension renamed farm_games_10_value (one namespace per cube) | not_declared |
| hero_playstyle | field farm_share_10_total shares its name with a metric | dimension renamed farm_share_10_total_value (one namespace per cube) | not_declared |
| hero_playstyle | field farm_games_20 shares its name with a metric | dimension renamed farm_games_20_value (one namespace per cube) | not_declared |
| hero_playstyle | field farm_share_20_total shares its name with a metric | dimension renamed farm_share_20_total_value (one namespace per cube) | not_declared |
| hero_playstyle | field last_hits_10_total shares its name with a metric | dimension renamed last_hits_10_total_value (one namespace per cube) | not_declared |
| hero_playstyle | field lane_games shares its name with a metric | dimension renamed lane_games_value (one namespace per cube) | not_declared |
| hero_playstyle | field lanes_won shares its name with a metric | dimension renamed lanes_won_value (one namespace per cube) | not_declared |
| hero_playstyle | field lanes_drawn shares its name with a metric | dimension renamed lanes_drawn_value (one namespace per cube) | not_declared |
| hero_playstyle | field lanes_lost shares its name with a metric | dimension renamed lanes_lost_value (one namespace per cube) | not_declared |
| hero_playstyle | field enemy_hero_damage_taken shares its name with a metric | dimension renamed enemy_hero_damage_taken_value (one namespace per cube) | not_declared |
| hero_playstyle | field hero_kill_deaths shares its name with a metric | dimension renamed hero_kill_deaths_value (one namespace per cube) | not_declared |
| hero_playstyle | field trade_deaths shares its name with a metric | dimension renamed trade_deaths_value (one namespace per cube) | not_declared |
| hero_playstyle | field observers_placed shares its name with a metric | dimension renamed observers_placed_value (one namespace per cube) | not_declared |
| hero_playstyle | field sentries_placed shares its name with a metric | dimension renamed sentries_placed_value (one namespace per cube) | not_declared |
| hero_playstyle | field runes_taken shares its name with a metric | dimension renamed runes_taken_value (one namespace per cube) | not_declared |
| hero_playstyle | field buybacks shares its name with a metric | dimension renamed buybacks_value (one namespace per cube) | not_declared |
| hero_position_meta | field position_share shares its name with a metric | dimension renamed position_share_value (one namespace per cube) | not_declared |
| lens drafts | untyped_fallback | DROPPED: a serving-config key the Cube lens has no use for | not_expressible |
| lens drafts | connections | DROPPED: a serving-config key the Cube lens has no use for | not_expressible |
| lens items | untyped_fallback | DROPPED: a serving-config key the Cube lens has no use for | not_expressible |
| lens items | connections | DROPPED: a serving-config key the Cube lens has no use for | not_expressible |
| lens playstyle | untyped_fallback | DROPPED: a serving-config key the Cube lens has no use for | not_expressible |
| lens playstyle | connections | DROPPED: a serving-config key the Cube lens has no use for | not_expressible |
| lens pro_meta | advantage_timeline reaches patches again via advantage_timeline.pro_matches | the view joins it by the first path found | not_expressible |
| lens pro_meta | match_leads reaches leagues again via match_leads.pro_matches | the view joins it by the first path found | not_expressible |
| lens pro_meta | match_leads reaches patches again via match_leads.pro_matches | the view joins it by the first path found | not_expressible |
| lens pro_meta | match_objectives reaches leagues again via match_objectives.pro_matches | the view joins it by the first path found | not_expressible |
| lens pro_meta | match_objectives reaches patches again via match_objectives.pro_matches | the view joins it by the first path found | not_expressible |
| lens pro_meta | player_performances reaches patches again via player_performances.pro_matches | the view joins it by the first path found | not_expressible |
| lens pro_meta | team_matches reaches leagues again via team_matches.pro_matches | the view joins it by the first path found | not_expressible |
| lens pro_meta | team_matches reaches patches again via team_matches.pro_matches | the view joins it by the first path found | not_expressible |
| lens pro_meta | team_matches reaches teams again via team_matches.pro_matches | the view joins it by the first path found | not_expressible |
| lens pro_meta | untyped_fallback | DROPPED: a serving-config key the Cube lens has no use for | not_expressible |
| lens pro_meta | connections | DROPPED: a serving-config key the Cube lens has no use for | not_expressible |
| lens pro_players | untyped_fallback | DROPPED: a serving-config key the Cube lens has no use for | not_expressible |
| lens pro_players | connections | DROPPED: a serving-config key the Cube lens has no use for | not_expressible |
| lens pub_meta | untyped_fallback | DROPPED: a serving-config key the Cube lens has no use for | not_expressible |
| lens pub_meta | connections | DROPPED: a serving-config key the Cube lens has no use for | not_expressible |
| definitions | comeback | DROPPED: sql without an about entity | not_declared |
| definitions | current_patch | DROPPED: sql without an about entity | not_declared |
| definitions | signature_hero | DROPPED: sql without an about entity | not_declared |

## Not native to Cube, carried as meta.dst or overlay (by design)

| how it is carried | failure mode without it |
|---|---|
| `additivity: level` + `snapshot_grain`: Cube sums a level across months; dst must pin the latest snapshot per bucket (meta.dst). | wrong_grain |
| `agg_time_field` (a measure's own clock): Cube applies whichever time dimension the query names; `meta.dst.clock` tells dst which one to name. | window_misbound |
| `default_time_field`: Cube has no default time dimension; `overlay.cubes.<cube>.default_time_dimension`. | window_misbound |
| `pinned_dimensions`: no Cube equivalent (overlay). | wrong_grain |
| `use_cases` / `common_questions` / blueprint `caveats`: routing text, overlay per cube. | unroutable |
| `internal` / `hide`: `public: false` on the cube, and no view lists the member; a hide with `except_groups` is listed under the view's `access_policy`, granted to those groups only (Cube's `contextToGroups` reads `security_context.dst.groups`), and overlay.hide. | hidden_column |
| Lens scope/policy (`not_for`, `not_computable`, `sources`, `access`, `expose`, `timezone`, `stale_after_days`): overlay.lenses. | scope_violation |
| Definitions without `sql`, ambiguous terms with readings/audiences: overlay.definitions / overlay.ambiguous. | ambiguous_metric |
| Certified answers stay SQL pairs in `lenses/<lens>/certified_answers.yaml`. | not_expressible |
| dst `fields` vs `dimensions`: both are Cube dimensions; the group-by hint is only the presence of `meta.dst.aliases`. | wrong_grain |
| Composite primary keys: every key column carries `primary_key: true`. | wrong_grain |
| View members are prefixed with the cube name (`prefix: true`, `<view>.<cube>_<member>`) only in a view where a member name occurs in two of its cubes (`month`, `entity`, the join key); a view whose cubes share no member name lists them bare (`<view>.<member>`). | not_declared |
| A Cube view resolves one join tree: a lens becomes `<lens>_lens` (scope, direct includes) plus one `<lens>_<fact>` view per cube with in-lens joins (the fact + the dimensions of every cube its many_to_one / one_to_one joins reach, by the first path found). | not_expressible |
| Primary keys are public (Cube hides them by default); an `internal` or hidden key stays `public: false`. | hidden_column |
