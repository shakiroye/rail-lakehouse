-- Le dépivotage des causes doit produire exactement 6 lignes par ligne de faits.
-- Échoue si la requête renvoie une ligne.
with fct as (
    select count(*) as lignes from {{ ref('fct_regularite_mensuelle') }}
),

mart as (
    select count(*) as lignes from {{ ref('mart_causes_retard') }}
)

select
    fct.lignes * 6 as lignes_attendues,
    mart.lignes    as lignes_mart
from fct
cross join mart
where fct.lignes * 6 != mart.lignes
