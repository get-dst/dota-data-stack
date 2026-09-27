{# A name as OpenDota typed it, without leading or trailing spaces; a blank name is null. #}
{% macro clean_name(expr) -%}
nullif(trim({{ expr }}), '')
{%- endmacro %}
