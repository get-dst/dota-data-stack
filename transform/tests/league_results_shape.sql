-- league_results has one row for every league in fact_match and no other; its games add
-- up to fact_match's; a winner is named exactly when final_status is 'final', and then
-- the runner-up is another team, the winner has the wins its format needs and more than
-- the runner-up, and the winner also won the league's last game (the tournament_winner
-- term reads the winner from that game). One row per offending league or total.
with fact_leagues as (
    select league_id, count(*) as matches from {{ ref('fact_match') }} group by 1
),

last_game as (
    select league_id, winner_team_id
    from {{ ref('fact_match') }}
    qualify row_number() over (partition by league_id order by started_at desc, match_id desc) = 1
)

select 'missing' as problem, f.league_id
from fact_leagues as f
left join {{ ref('league_results') }} as r on r.league_id = f.league_id
where r.league_id is null
union all
select 'not in fact_match', r.league_id
from {{ ref('league_results') }} as r
left join fact_leagues as f on f.league_id = r.league_id
where f.league_id is null
union all
select 'matches', r.league_id
from {{ ref('league_results') }} as r
inner join fact_leagues as f on f.league_id = r.league_id
where r.matches <> f.matches
union all
select 'winner without final', league_id
from {{ ref('league_results') }}
where (winner_team_id is not null) <> (final_status = 'final')
union all
select 'winner is runner-up', league_id
from {{ ref('league_results') }}
where final_status = 'final'
    and (runner_up_team_id is null or winner_team_id = runner_up_team_id)
union all
select 'score', league_id
from {{ ref('league_results') }}
where final_status = 'final'
    and (winner_games <> (final_best_of + 1) / 2 or runner_up_games >= winner_games)
union all
select 'last game', r.league_id
from {{ ref('league_results') }} as r
inner join last_game as g on g.league_id = r.league_id
where r.final_status = 'final' and g.winner_team_id is distinct from r.winner_team_id
