with spine as (

    -- La source commence en 2018-01 (voir docs/exploration.md)
    {{ dbt_utils.date_spine(
        datepart="month",
        start_date="cast('2018-01-01' as date)",
        end_date="add_months(date_trunc('month', current_date()), 1)"
    ) }}

)

select
    cast(date_month as date)                                                    as mois,
    year(date_month)                                                            as annee,
    quarter(date_month)                                                         as trimestre,
    month(date_month)                                                           as num_mois,
    concat(
        element_at(array('janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet',
                         'août', 'septembre', 'octobre', 'novembre', 'décembre'), month(date_month)),
        ' ', year(date_month)
    )                                                                           as libelle_mois,
    month(date_month) in (7, 8)                                                 as est_ete
from spine
