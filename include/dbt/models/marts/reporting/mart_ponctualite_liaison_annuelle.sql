with par_annee as (

    select
        m.annee,
        f.liaison_id,
        l.libelle_liaison,
        l.service,
        sum(f.nb_trains_prevus) as nb_trains_prevus,
        sum(f.nb_trains_circules) as nb_trains_circules,
        sum(f.nb_annulations) as nb_annulations,
        sum(f.nb_trains_retard_arrivee) as nb_trains_retard_arrivee,
        -- moyenne pondérée : jamais de moyenne de taux
        try_divide(sum(f.nb_annulations), sum(f.nb_trains_prevus)) as taux_annulation,
        1 - try_divide(sum(f.nb_trains_retard_arrivee), sum(f.nb_trains_circules)) as taux_ponctualite_arrivee,
        try_divide(sum(f.nb_trains_retard_sup_30), sum(f.nb_trains_circules)) as part_retards_sup_30
    from {{ ref('fct_regularite_mensuelle') }} as f
    inner join {{ ref('dim_liaison') }} as l on f.liaison_id = l.liaison_id
    inner join {{ ref('dim_mois') }} as m on f.mois = m.mois
    group by m.annee, f.liaison_id, l.libelle_liaison, l.service

),

comparables as (

    -- Une liaison trop peu fréquentée sur l'année n'est pas comparable aux autres
    select
        *,
        nb_trains_circules >= {{ var('seuil_trains_comparables', 200) }} as est_comparable
    from par_annee

)

select
    *,
    -- Rang calculé uniquement parmi les liaisons comparables, NULL pour les autres
    case
        when est_comparable then rank() over (
            partition by annee, est_comparable
            order by taux_ponctualite_arrivee asc nulls last
        )
    end as rang_moins_ponctuelle
from comparables
