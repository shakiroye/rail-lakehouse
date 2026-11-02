-- Réconciliation faits -> mart annuel : par année, mêmes totaux de trains circulés et en retard.
-- Échoue si la requête renvoie une ligne.
with fct as (
    select
        year(mois)                      as annee,
        sum(nb_trains_circules)         as circules,
        sum(nb_trains_retard_arrivee)   as retards
    from {{ ref('fct_regularite_mensuelle') }}
    group by year(mois)
),

mart as (
    select
        annee,
        sum(nb_trains_circules)         as circules,
        sum(nb_trains_retard_arrivee)   as retards
    from {{ ref('mart_ponctualite_liaison_annuelle') }}
    group by annee
)

select
    coalesce(fct.annee, mart.annee) as annee,
    fct.circules                    as circules_faits,
    mart.circules                   as circules_mart,
    fct.retards                     as retards_faits,
    mart.retards                    as retards_mart
from fct
full outer join mart on fct.annee = mart.annee
where fct.circules is distinct from mart.circules
   or fct.retards is distinct from mart.retards
