{#
    prod     : schémas exacts (silver, gold)
    dev / ci : schémas préfixés par le schéma de la cible (dbt_dev_silver, ci_pr_12_gold...)
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- elif target.name == 'prod' -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ target.schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
