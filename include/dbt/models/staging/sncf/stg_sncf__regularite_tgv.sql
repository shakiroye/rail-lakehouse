with source as (

    select * from {{ source('sncf', 'regularite_tgv') }}

),

-- Chaque fichier contient tout l'historique : on ne garde que le plus récent.
-- Les fichiers sont nommés regularite_tgv_AAAAMMJJ.csv, donc max() = le dernier.
dernier_instantane as (

    select *
    from source
    where _source_file = (select max(fichiers._source_file) from source as fichiers)

),

-- Écartées volontairement (voir docs/exploration.md) :
--   commentaire_* : texte libre, vide depuis 2020
--   retard_moyen_trains_en_retard_15_si_liaison_concurrencee_par_vol : sens instable dans le temps
renamed as (

    select
        to_date(concat(`date`, '-01')) as mois,
        -- "service" est un mot-clé Databricks, mais c'est le nom de la colonne source : conservé
        upper(trim(service)) as service,  -- noqa: RF04
        {{ clean_station_name('gare_de_depart') }} as gare_depart,
        {{ clean_station_name('gare_d_arrivee') }} as gare_arrivee,

        {{ to_num('duree_moyenne_du_trajet', 'int') }} as duree_moyenne_min,
        {{ to_num('nombre_de_circulations_prevues', 'int') }} as nb_trains_prevus,
        {{ to_num('nombre_de_trains_annules', 'int') }} as nb_annulations,

        {{ to_num('nombre_de_trains_en_retard_au_depart', 'int') }} as nb_trains_retard_depart,
        {{ to_num('retard_moyen_des_trains_en_retard_au_depart') }} as retard_moyen_depart_min,
        {{ to_num('retard_moyen_de_tous_les_trains_au_depart') }} as retard_moyen_tous_trains_depart_min,

        {{ to_num('nombre_de_trains_en_retard_a_l_arrivee', 'int') }} as nb_trains_retard_arrivee,
        {{ to_num('retard_moyen_des_trains_en_retard_a_l_arrivee') }} as retard_moyen_arrivee_min,
        {{ to_num('retard_moyen_de_tous_les_trains_a_l_arrivee') }} as retard_moyen_tous_trains_arrivee_min,
        {{ to_num('nombre_trains_en_retard_15min', 'int') }} as nb_trains_retard_sup_15,
        {{ to_num('nombre_trains_en_retard_30min', 'int') }} as nb_trains_retard_sup_30,
        {{ to_num('nombre_trains_en_retard_60min', 'int') }} as nb_trains_retard_sup_60,

        {{ to_num('prct_retard_pour_causes_externes') }} as pct_cause_externe,
        {{ to_num('prct_retard_pour_cause_infrastructure') }} as pct_cause_infrastructure,
        {{ to_num('prct_retard_pour_cause_gestion_trafic') }} as pct_cause_gestion_trafic,
        {{ to_num('prct_retard_pour_cause_materiel_roulant') }} as pct_cause_materiel_roulant,
        {{ to_num('prct_retard_pour_cause_gestion_en_gare_et_reutilisation_de_materiel') }}
            as pct_cause_gestion_gare,
        {{ to_num('prct_retard_pour_cause_prise_en_compte_voyageurs_affluence_gestions_psh_correspondances') }}
            as pct_cause_prise_en_charge_voyageurs,

        _source_file,
        _ingested_at

    from dernier_instantane

)

select * from renamed
