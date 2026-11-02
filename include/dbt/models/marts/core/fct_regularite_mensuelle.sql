{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['liaison_id', 'mois'],
    on_schema_change='append_new_columns'
) }}

select
    liaison_id,
    gare_depart_id,
    gare_arrivee_id,
    mois,
    nb_trains_prevus,
    nb_annulations,
    nb_trains_circules,
    nb_trains_retard_arrivee,
    nb_trains_retard_sup_15,
    nb_trains_retard_sup_30,
    nb_trains_retard_sup_60,
    retard_moyen_arrivee_min,
    taux_annulation,
    taux_ponctualite_arrivee,
    part_retards_sup_30,
    cause_dominante,
    pct_cause_externe,
    pct_cause_infrastructure,
    pct_cause_gestion_trafic,
    pct_cause_materiel_roulant,
    pct_cause_gestion_gare,
    pct_cause_prise_en_charge_voyageurs,
    current_timestamp() as _dbt_updated_at
from {{ ref('int_regularite__indicateurs') }}

{% if is_incremental() %}
  -- la SNCF peut corriger les derniers mois publiés : on retraite une fenêtre glissante
  where mois >= (select add_months(max(mois), -{{ var('lookback_mois', 3) }}) from {{ this }})
{% endif %}
