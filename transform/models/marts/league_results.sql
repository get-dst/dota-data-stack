-- One row per league in the pro tables: its dates, games and series in the loaded window,
-- and the result of its final. OpenDota marks neither a final nor the end of a league, so
-- the final is read from the games: the series holding the league's last game (games of
-- one series share series_id; a game without one stands alone). final_status says whether
-- that series names a winner and, when it does not, why; winner and runner-up are filled
-- only when final_status is 'final'. The checks run in the order of the case below.
with recursive sides as (
    select
        league_id,
        match_id,
        started_at,
        coalesce(cast(nullif(series_id, 0) as varchar), 'match ' || cast(match_id as varchar)) as series_key,
        nullif(series_id, 0) as series_id,
        series_type,
        team_id,
        team_name,
        opponent_team_id,
        is_win
    from {{ ref('fact_team_match') }}
),

series as (
    select
        league_id,
        series_key,
        max(series_id) as series_id,
        case max(series_type) when 0 then 1 when 1 then 3 when 2 then 5 when 3 then 2 end as best_of,
        min(started_at) as first_started_at,
        max(started_at) as last_started_at,
        count(distinct team_id) as teams,
        count(*) filter (where team_id is null) as unidentified_sides
    from sides
    group by 1, 2
),

ranked as (
    select
        *,
        row_number() over (
            partition by league_id order by last_started_at desc, first_started_at desc, series_key desc
        ) as recency_rank,
        max(best_of) over (partition by league_id) as league_longest_best_of
    from series
),

final_series as (
    select
        f.*,
        exists (
            select 1 from ranked as o
            where o.league_id = f.league_id and o.recency_rank > 1 and o.last_started_at >= f.first_started_at
        ) as has_parallel_series
    from ranked as f
    where f.recency_rank = 1
),

finalists as (
    select
        s.league_id,
        s.team_id,
        arg_max(s.team_name, s.started_at) as team_name,
        count(*) filter (where s.is_win) as games_won
    from sides as s
    inner join final_series as f on f.league_id = s.league_id and f.series_key = s.series_key
    where s.team_id is not null
    group by 1, 2
),

final_score as (
    select
        league_id,
        arg_max(team_id, games_won) as winner_team_id,
        arg_max(team_name, games_won) as winner_team_name,
        arg_min(team_id, games_won) as runner_up_team_id,
        arg_min(team_name, games_won) as runner_up_team_name,
        max(games_won) as winner_games,
        min(games_won) as runner_up_games
    from finalists
    group by 1
    having count(*) = 2
),

-- The teams the finalists are connected to through games played in the league. In a
-- league of separate brackets (regional qualifiers under one league id) that is one
-- bracket, a minority of the league's teams, and no single team won the league.
edges as (
    select distinct league_id, team_id, opponent_team_id
    from sides
    where team_id is not null and opponent_team_id is not null
),

reach (league_id, team_id) as (
    select league_id, winner_team_id from final_score
    union
    select e.league_id, e.opponent_team_id
    from reach as r
    inner join edges as e on e.league_id = r.league_id and e.team_id = r.team_id
),

leagues as (
    select
        league_id,
        min(started_at) as first_started_at,
        max(started_at) as last_started_at,
        count(distinct match_id) as matches,
        count(distinct series_key) as series,
        count(distinct team_id) as teams
    from sides
    group by 1
),

newest as (
    select max(started_at) as newest_started_at from {{ ref('fact_match') }}
),

judged as (
    select
        l.*,
        f.series_id as final_series_id,
        f.best_of as final_best_of,
        s.winner_team_id,
        s.winner_team_name,
        s.runner_up_team_id,
        s.runner_up_team_name,
        s.winner_games,
        s.runner_up_games,
        case
            -- Leagues pause between stages; three weeks without a game is taken as the end.
            when l.last_started_at > n.newest_started_at - interval 21 days then 'in progress'
            when f.series_id is null then 'no series id'
            when f.has_parallel_series then 'parallel series'
            when f.unidentified_sides > 0 or f.teams <> 2 then 'teams not identified'
            -- A final is a best of 3 or 5, and no shorter than any series before it.
            when coalesce(f.best_of, 0) not in (3, 5) or f.best_of < f.league_longest_best_of then 'not a final format'
            when (select count(*) from reach as r where r.league_id = l.league_id) * 2 <= l.teams then 'several brackets'
            -- Games missing from the feed, or a drawn series.
            when s.winner_games < (f.best_of + 1) / 2 or s.winner_games = s.runner_up_games then 'incomplete series'
            else 'final'
        end as final_status
    from leagues as l
    cross join newest as n
    inner join final_series as f on f.league_id = l.league_id
    left join final_score as s on s.league_id = l.league_id
)

select
    j.league_id,
    d.league_name,
    d.league_tier,
    cast(timezone('UTC', j.first_started_at) as date) as first_match_date,
    cast(timezone('UTC', j.last_started_at) as date) as last_match_date,
    j.matches,
    j.series,
    j.teams,
    j.final_series_id,
    j.final_best_of,
    j.final_status,
    case when j.final_status = 'final' then j.winner_team_id end as winner_team_id,
    case when j.final_status = 'final' then j.winner_team_name end as winner_team_name,
    case when j.final_status = 'final' then j.runner_up_team_id end as runner_up_team_id,
    case when j.final_status = 'final' then j.runner_up_team_name end as runner_up_team_name,
    case when j.final_status = 'final' then j.winner_games end as winner_games,
    case when j.final_status = 'final' then j.runner_up_games end as runner_up_games,
    case when j.final_status = 'final'
        then cast(j.winner_games as varchar) || '-' || cast(j.runner_up_games as varchar)
    end as final_score
from judged as j
inner join {{ ref('dim_league') }} as d on d.league_id = j.league_id
