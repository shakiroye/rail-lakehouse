"""Versions factices des macros dbt_utils, pour que sqlfluff puisse analyser les modèles sans dbt.

Elles renvoient un SQL valide de même forme : seul le lint les utilise, jamais dbt.
"""


def generate_surrogate_key(field_list):
    return "md5(concat_ws('-', " + ", ".join(field_list) + "))"


def date_spine(datepart, start_date, end_date):
    return f"select explode(sequence({start_date}, {end_date}, interval 1 {datepart})) as date_{datepart}"
