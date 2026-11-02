with causes as (

    select
        liaison_id,
        mois,
        nb_trains_retard_arrivee,
        stack(6,
            'Externe',                   pct_cause_externe,
            'Infrastructure',            pct_cause_infrastructure,
            'Gestion du trafic',         pct_cause_gestion_trafic,
            'Matériel roulant',          pct_cause_materiel_roulant,
            'Gestion en gare',           pct_cause_gestion_gare,
            'Prise en charge voyageurs', pct_cause_prise_en_charge_voyageurs
        ) as (cause, pct_cause)
    from {{ ref('fct_regularite_mensuelle') }}

)

select
    liaison_id,
    mois,
    cause,
    pct_cause,
    round(nb_trains_retard_arrivee * pct_cause / 100, 1) as nb_trains_retard_attribues
from causes
where pct_cause is not null
