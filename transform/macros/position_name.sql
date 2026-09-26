{# The derived position (fact_player_match.position) as the word people use for it. #}
{% macro position_name(expr) -%}
case {{ expr }} when 1 then 'carry' when 2 then 'mid' when 3 then 'offlane' when 4 then 'soft support' when 5 then 'hard support' end
{%- endmacro %}
