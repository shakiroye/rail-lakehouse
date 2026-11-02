{#
    Conversion robuste d'une colonne texte en nombre : espaces, virgule décimale, valeurs vides.
    Une valeur non convertible donne NULL au lieu de faire échouer le modèle.
#}
{% macro to_num(col, type='double') -%}
    {%- if type == 'int' -%}
        cast(try_cast(replace(trim({{ col }}), ',', '.') as double) as int)
    {%- else -%}
        try_cast(replace(trim({{ col }}), ',', '.') as {{ type }})
    {%- endif -%}
{%- endmacro %}
