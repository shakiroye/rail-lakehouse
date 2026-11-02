with stg as (

    select * from {{ ref('stg_sncf__regularite_tgv') }}

),

circulations as (

    select
        {{ dbt_utils.generate_surrogate_key(['service', 'gare_depart', 'gare_arrivee']) }} as liaison_id,
        {{ dbt_utils.generate_surrogate_key(['gare_depart']) }} as gare_depart_id,
        {{ dbt_utils.generate_surrogate_key(['gare_arrivee']) }} as gare_arrivee_id,
        *,
        -- Borné à 0 : d'avril à juin 2020, la source compte des annulations sur des liaisons à 0 train prévu
        greatest(nb_trains_prevus - nb_annulations, 0) as nb_trains_circules,
        greatest(
            pct_cause_externe, pct_cause_infrastructure, pct_cause_gestion_trafic,
            pct_cause_materiel_roulant, pct_cause_gestion_gare,
            pct_cause_prise_en_charge_voyageurs
        ) as pct_cause_max
    from stg

)

select
    * except (pct_cause_max),

    try_divide(nb_annulations, nb_trains_prevus) as taux_annulation,
    1 - try_divide(nb_trains_retard_arrivee, nb_trains_circules) as taux_ponctualite_arrivee,
    try_divide(nb_trains_retard_sup_30, nb_trains_circules) as part_retards_sup_30,

    -- NULL sans retard, et aussi quand toutes les causes valent 0 (causes manquantes de 2018-05 à 2018-08)
    case
        when coalesce(nb_trains_retard_arrivee, 0) = 0 or coalesce(pct_cause_max, 0) = 0 then null
        when pct_cause_max = pct_cause_externe then 'Externe'
        when pct_cause_max = pct_cause_infrastructure then 'Infrastructure'
        when pct_cause_max = pct_cause_gestion_trafic then 'Gestion du trafic'
        when pct_cause_max = pct_cause_materiel_roulant then 'Matériel roulant'
        when pct_cause_max = pct_cause_gestion_gare then 'Gestion en gare'
        when pct_cause_max = pct_cause_prise_en_charge_voyageurs then 'Prise en charge voyageurs'
    end as cause_dominante

from circulations
