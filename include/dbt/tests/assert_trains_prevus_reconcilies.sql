-- Réconciliation staging -> faits : aucun train prévu ne doit être perdu ni dupliqué.
-- Échoue si la requête renvoie une ligne.
with stg as (
    select sum(nb_trains_prevus) as total from {{ ref('stg_sncf__regularite_tgv') }}
),

fct as (
    select sum(nb_trains_prevus) as total from {{ ref('fct_regularite_mensuelle') }}
)

select
    stg.total as total_staging,
    fct.total as total_faits
from stg
cross join fct
where stg.total != fct.total
