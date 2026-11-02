select
    liaison_id,
    service,
    gare_depart_id,
    gare_arrivee_id,
    concat(gare_depart, ' > ', gare_arrivee)                                     as libelle_liaison,
    -- durée de trajet la plus récente connue (hors mois sans train, où la source indique 0)
    max_by(duree_moyenne_min, mois) filter (where duree_moyenne_min > 0)          as duree_moyenne_min,
    min(mois)                                                                     as premier_mois,
    max(mois)                                                                     as dernier_mois
from {{ ref('int_regularite__indicateurs') }}
group by all
