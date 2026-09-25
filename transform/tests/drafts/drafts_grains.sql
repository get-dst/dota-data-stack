-- Each drafts-area mart has the grain its docs state: no key appears twice.
select * from (
select 'draft_phases' as model, count(*) as dupes from (
    select match_id, draft_order from {{ ref('draft_phases') }}
    group by 1, 2 having count(*) > 1) as d
union all
select 'hero_draft_stats', count(*) from (
    select patch_id, hero_id from {{ ref('hero_draft_stats') }}
    group by 1, 2 having count(*) > 1) as d
union all
select 'pro_draft_matchups', count(*) from (
    select patch_id, hero_id, opponent_hero_id from {{ ref('pro_draft_matchups') }}
    group by 1, 2, 3 having count(*) > 1) as d
union all
select 'lane_pairings', count(*) from (
    select patch_id, lane_role, hero_id, position, partner_hero_id, partner_position
    from {{ ref('lane_pairings') }}
    group by 1, 2, 3, 4, 5, 6 having count(*) > 1) as d
union all
select 'team_lineups', count(*) from (
    select match_id, is_radiant from {{ ref('team_lineups') }}
    group by 1, 2 having count(*) > 1) as d
union all
select 'team_signature_heroes', count(*) from (
    select team_id, patch_id, hero_id from {{ ref('team_signature_heroes') }}
    group by 1, 2, 3 having count(*) > 1) as d
) as grains
where dupes > 0
