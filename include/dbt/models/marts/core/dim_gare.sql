with gares as (

    select
        gare_depart_id as gare_id,
        gare_depart as nom_gare
    from {{ ref('int_regularite__indicateurs') }}
    union distinct
    select
        gare_arrivee_id,
        gare_arrivee
    from {{ ref('int_regularite__indicateurs') }}

)

select
    gare_id,
    nom_gare,
    nom_gare like 'PARIS%' as est_gare_parisienne
from gares
