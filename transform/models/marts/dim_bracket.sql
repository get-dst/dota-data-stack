-- Rank brackets as Dota names them. The public feed carries the average rank tier
-- of the players in a match (tens digit = bracket, ones digit = stars).
select * from (
    select 1 as bracket_id, 'Herald' as bracket_name
    union all select 2, 'Guardian'
    union all select 3, 'Crusader'
    union all select 4, 'Archon'
    union all select 5, 'Legend'
    union all select 6, 'Ancient'
    union all select 7, 'Divine'
    union all select 8, 'Immortal'
) as b
