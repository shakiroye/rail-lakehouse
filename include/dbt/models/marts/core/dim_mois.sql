-- La source commence en 2018-01 (voir docs/exploration.md)
with spine as (

    {{ dbt_utils.date_spine(
        datepart="month",
        start_date="cast('2018-01-01' as date)",
        end_date="add_months(date_trunc('month', current_date()), 1)"
    ) }}

),

mois_fr as (

    select array(
        'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet',
        'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ) as noms

)

select
    cast(spine.date_month as date) as mois,
    year(spine.date_month) as annee,
    quarter(spine.date_month) as trimestre,
    month(spine.date_month) as num_mois,
    concat(element_at(mois_fr.noms, month(spine.date_month)), ' ', year(spine.date_month)) as libelle_mois,
    month(spine.date_month) in (7, 8) as est_ete
from spine
cross join mois_fr
