{# Nom de gare normalisé : majuscules, sans espaces en bordure ni espaces multiples #}
{% macro clean_station_name(col) -%}
    upper(trim(regexp_replace({{ col }}, '\\s+', ' ')))
{%- endmacro %}
