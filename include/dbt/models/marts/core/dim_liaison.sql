with liaisons as (

    select
        liaison_id,
        service,
        gare_depart_id,
        gare_arrivee_id,
        concat(gare_depart, ' > ', gare_arrivee) as trajet,
        -- durée de trajet la plus récente connue (hors mois sans train, où la source indique 0)
        max_by(duree_moyenne_min, mois) filter (where duree_moyenne_min > 0) as duree_moyenne_min,
        min(mois) as premier_mois,
        max(mois) as dernier_mois
    from {{ ref('int_regularite__indicateurs') }}
    group by all

)

select
    liaison_id,
    service,
    gare_depart_id,
    gare_arrivee_id,
    -- Libellé unique : un même trajet peut exister en NATIONAL et en INTERNATIONAL
    -- (14 trajets en 2025-07..09, Paris Lyon - Barcelona) ; on suffixe alors la version internationale
    case
        when
            service = 'INTERNATIONAL'
            and count(*) over (partition by gare_depart_id, gare_arrivee_id) > 1
            then concat(trajet, ' (international)')
        else trajet
    end as libelle_liaison,
    duree_moyenne_min,
    premier_mois,
    dernier_mois
from liaisons
