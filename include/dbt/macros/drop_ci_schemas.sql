{#
    Supprime les schémas créés par une exécution de CI (ci_pr_12, ci_pr_12_silver, ci_pr_12_gold, ci_pr_12_dq).
    Garde-fou : refuse de s'exécuter si le schéma cible ne commence pas par "ci", pour ne jamais toucher à la prod.
    Usage : dbt run-operation drop_ci_schemas --target ci
#}
{% macro drop_ci_schemas() %}
    {% if not target.schema.startswith('ci') %}
        {{ exceptions.raise_compiler_error("Refus : cette macro ne supprime que des schémas ci*, cible actuelle : " ~ target.schema) }}
    {% endif %}
    {% for suffix in ['', '_silver', '_gold', '_dq'] %}
        {% set sql %}drop schema if exists {{ target.database }}.{{ target.schema }}{{ suffix }} cascade{% endset %}
        {% do run_query(sql) %}
        {{ log("Supprimé : " ~ target.database ~ "." ~ target.schema ~ suffix, info=True) }}
    {% endfor %}
{% endmacro %}
