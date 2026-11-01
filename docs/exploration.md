# Exploration de la source : régularité mensuelle TGV par liaison

Analyse réalisée le 2 novembre 2026 sur le fichier complet (notebook : [`notebooks/01_exploration.ipynb`](../notebooks/01_exploration.ipynb)).

- **Source :** [Régularité mensuelle TGV par liaisons](https://www.data.gouv.fr/datasets/regularite-mensuelle-tgv-par-liaisons) (AQST / SNCF), licence ODbL
- **URL de téléchargement :** `https://www.data.gouv.fr/api/1/datasets/r/91fe399d-cafa-4e72-8ba3-56d8717fdad4`
- **Format :** CSV UTF-8 avec BOM, séparateur `;`, fins de ligne LF, environ 2,9 Mo
- **Volume :** 12 907 enregistrements, 26 colonnes, mais 15 424 lignes physiques (voir Q5)
- **Période :** de 2018-01 à 2026-09 (105 mois). Chaque téléchargement contient tout l'historique.
- **Couverture :** 146 liaisons (service × gare de départ × gare d'arrivée), 59 gares, entre 118 et 135 lignes par mois
- **Service :** `National` (11 339 lignes) et `International` (1 568 lignes)

> La fiche officielle précise que ce jeu ne doit pas servir à calculer un taux de ponctualité global TGV ou par axe. Les indicateurs du projet restent **par liaison**.

## Dictionnaire des colonnes

Noms après la normalisation `snake_case` de l'ingestion, c'est-à-dire tels qu'ils apparaissent dans la table bronze.

| Colonne bronze | Contenu | Utilisation |
| --- | --- | --- |
| `date` | Mois observé, format `AAAA-MM` | clé |
| `service` | `National` ou `International` | clé |
| `gare_de_depart` | Nom de la gare de départ | clé |
| `gare_d_arrivee` | Nom de la gare d'arrivée | clé |
| `duree_moyenne_du_trajet` | Durée moyenne du trajet, en minutes | gardée |
| `nombre_de_circulations_prevues` | Trains programmés | gardée |
| `nombre_de_trains_annules` | Trains annulés | gardée |
| `commentaire_annulations` | Texte libre, toujours vide | **écartée** |
| `nombre_de_trains_en_retard_au_depart` | Trains partis en retard | gardée |
| `retard_moyen_des_trains_en_retard_au_depart` | Retard moyen des seuls trains en retard au départ (min) | gardée |
| `retard_moyen_de_tous_les_trains_au_depart` | Retard moyen de tous les trains au départ (min) | gardée |
| `commentaire_retards_au_depart` | Texte libre, toujours vide | **écartée** |
| `nombre_de_trains_en_retard_a_l_arrivee` | Trains arrivés en retard | gardée |
| `retard_moyen_des_trains_en_retard_a_l_arrivee` | Retard moyen des seuls trains en retard à l'arrivée (min) | gardée |
| `retard_moyen_de_tous_les_trains_a_l_arrivee` | Retard moyen de tous les trains à l'arrivée (min) | gardée |
| `commentaire_retards_a_l_arrivee` | Texte libre multiligne, rempli seulement en 2018-2019 | **écartée** |
| `nombre_trains_en_retard_15min` | Trains en retard de plus de 15 min | gardée |
| `retard_moyen_trains_en_retard_15_si_liaison_concurrencee_par_vol` | Sens instable dans le temps (voir Q4) | **écartée** |
| `nombre_trains_en_retard_30min` | Trains en retard de plus de 30 min (inexploitable au T1 2025) | gardée, avec test |
| `nombre_trains_en_retard_60min` | Trains en retard de plus de 60 min | gardée |
| `prct_retard_pour_causes_externes` | Part des retards : causes externes (météo, obstacles, malveillance…) | gardée |
| `prct_retard_pour_cause_infrastructure` | Part des retards : infrastructure | gardée |
| `prct_retard_pour_cause_gestion_trafic` | Part des retards : gestion du trafic | gardée |
| `prct_retard_pour_cause_materiel_roulant` | Part des retards : matériel roulant | gardée |
| `prct_retard_pour_cause_gestion_en_gare_et_reutilisation_de_materiel` | Part des retards : gestion en gare et réutilisation de matériel | gardée |
| `prct_retard_pour_cause_prise_en_compte_voyageurs_affluence_gestions_psh_correspondances` | Part des retards : prise en charge des voyageurs | gardée |

**Écart avec le lab :** les noms réels ne sont pas ceux utilisés dans les exemples du lab (`nb_train_prevu`, `prct_cause_infra`…). Le modèle staging (étape 4) devra lire les noms ci-dessus.

## Q1. Quelle est la granularité exacte d'une ligne ?

**Une ligne = un mois × un service × une gare de départ × une gare d'arrivée.**

- **Aucun doublon** sur la clé `(date, service, gare_de_depart, gare_d_arrivee)`.
- **Le service est indispensable dans la clé.** Sans lui, on trouve 42 doublons. Entre 2025-07 et 2025-09, 14 liaisons au départ ou à destination de Paris Lyon, Paris Est et Lyon Part Dieu existent à la fois en `National` et en `International` le même mois, avec des volumes différents.
- **Une liaison peut changer de service.** Paris Lyon ↔ Barcelona est `International` jusqu'en 2025-09, puis `National` à partir de 2025-10. Avec une clé de liaison qui inclut le service, ce trajet produit donc deux `liaison_id`. C'est un choix à assumer et à documenter.
- **Toutes les liaisons ne couvrent pas les 105 mois.** Les 4 liaisons Paris Vaugirard n'existent qu'en 2018. Madrid ↔ Marseille s'arrête en 2022-12, et Tourcoing → Marseille n'a que 13 mois. Les 14 liaisons internationales citées plus haut ne couvrent que 3 mois.

## Q2. Les noms de gares sont-ils propres ?

**Oui.** Les 59 gares sont toutes en majuscules, sans accent, sans espace en double ni en bordure, et sans variante d'un même nom.

Points à noter :

- **Les abréviations ne sont pas uniformes :** `ST` (`BORDEAUX ST JEAN`, `ST MALO`) mais `SAINT` (`ANGERS SAINT LAUD`, `SAINT ETIENNE CHATEAUCREUX`). Cela ne gêne pas le projet, mais il faudra en tenir compte pour le rapprochement avec le référentiel des gares (piste « deuxième source »).
- **Certaines « gares » n'en sont pas :** `ITALIE` est un regroupement de destinations, pas une gare. Les gares étrangères sont nommées dans des langues différentes (`FRANCFORT`, `GENEVE` mais `BARCELONA`).
- **Un nom contient des parenthèses :** `BELLEGARDE (AIN)`.

La macro `clean_station_name` reste utile par sécurité, car un futur fichier pourrait être moins propre, mais elle ne change rien aujourd'hui.

## Q3. Les six pourcentages de causes somment-ils à 100 ?

**Oui, dans l'immense majorité des cas.** Sur les 12 715 lignes qui ont au moins un train en retard à l'arrivée, 12 626 somment à 100 (à 1 point près).

- **Sans retard, tout vaut 0 :** les 192 lignes sans train en retard ont leurs six pourcentages à **0**, et non à `NULL`.
- **80 lignes avec retards ont pourtant 0 partout.** Elles se concentrent sur 2018-05 à 2018-08 (16 à 17 par mois). Les causes sont manquantes ces mois-là.
- **9 lignes sont légèrement sous 100** (entre 84,6 et 98,6).
- **Aucune valeur aberrante :** pas de valeur nulle (`NaN`), négative ou supérieure à 100.

**Conséquence pour la cause dominante :** il ne suffit pas de tester `nb_trains_retard_arrivee = 0`. Pour les 80 lignes de 2018, `greatest(...) = 0`, et le `case` du lab renverrait « Externe » à tort. Il faut aussi renvoyer `NULL` quand `greatest(...) = 0`.

## Q4. Y a-t-il des valeurs impossibles ?

Oui, et elles se regroupent sur quelques périodes identifiables.

| Anomalie | Lignes | Période | Interprétation |
| --- | --- | --- | --- |
| 0 train prévu | 73 | 2020-04 à 2020-12 | Confinement : liaison suspendue |
| Annulés > prévus | 63 | 2020-04 à 2020-06 | Toujours avec 0 train prévu : les annulations sont comptées alors que la liaison est suspendue. Trains circulés négatifs. |
| Retard arrivée > circulés | 63 | 2020-04 à 2020-06 | Mêmes lignes : conséquence du point précédent |
| Durée moyenne du trajet = 0 | 73 | 2020 | Mêmes lignes que « 0 train prévu » |
| Retard > 30 min **négatif** | 43 | 2025-01 à 2025-03 | Valeurs impossibles (jusqu'à -44) |
| Retard > 60 min > retard > 30 min | 354 | 2025-01 à 2025-03 | 354 lignes sur 363 au T1 2025 : la colonne « > 30 min » est inexploitable sur ce trimestre |
| Retard > 15 min > retard arrivée | 31 | surtout 2018-2019 | Légère incohérence de la source |
| Retard > 30 min > retard > 15 min | 3 | 2020-05, 2025-03 | Légère incohérence de la source |
| Retard moyen de tous les trains à l'arrivée < 0 | 122 | surtout 2020-2021 (72 lignes), trafic réduit | Trains en avance : plausible quand c'est proche de 0, aberrant pour le minimum (-472 min) |
| Retard moyen **des trains en retard** à l'arrivée < 0 | 2 | — | Impossible par définition |

La colonne `retard_moyen_trains_en_retard_15_si_liaison_concurrencee_par_vol` change de sens. En 2018, elle vaut en moyenne 7,1 min, exactement comme le retard moyen de tous les trains. Ensuite, elle monte à 29-47 min, plus que le retard moyen des trains en retard. Elle n'est donc pas comparable dans le temps et sera écartée.

## Q5. Quelles colonnes sont du texte libre ?

Les trois colonnes `commentaire_*` :

- **`commentaire_annulations` et `commentaire_retards_au_depart` :** toujours vides.
- **`commentaire_retards_a_l_arrivee` :** remplie dans 29 % des lignes en 2018, 16 % en 2019, puis plus jamais. Elle contient des récits d'incidents (« Tempête Carmen… »), dont 351 **sur plusieurs lignes**, entre guillemets. Certains contiennent des guillemets doublés (`""`).

Elles restent en bronze (on ne jette rien) mais sont **écartées dès le staging**.

**Conséquence pour l'ingestion :** à cause des retours à la ligne et des guillemets doublés, le `COPY INTO` de l'étape 2 doit lire le CSV avec `'multiLine' = 'true'` et `'escape' = '"'`. Sinon, Databricks coupe les enregistrements au milieu des commentaires. Contrôle à faire : la table bronze doit contenir 12 907 lignes, et non 15 424.

## Indicateurs métier

Tous les indicateurs se calculent au grain **liaison × mois**. Pour agréger (par année, par service), on somme les numérateurs et les dénominateurs, **jamais une moyenne de taux**.

| Indicateur | Formule (colonnes staging) | Remarque |
| --- | --- | --- |
| Trains circulés | `greatest(nb_trains_prevus - nb_annulations, 0)` | Le `greatest` neutralise les 63 lignes de 2020 où les annulés dépassent les prévus |
| Taux d'annulation | `try_divide(nb_annulations, nb_trains_prevus)` | `NULL` quand 0 train prévu |
| Taux de ponctualité à l'arrivée | `1 - try_divide(nb_trains_retard_arrivee, nb_trains_circules)` | `NULL` quand 0 train circulé |
| Part des gros retards | `try_divide(nb_trains_retard_sup_30, nb_trains_circules)` | Non fiable au T1 2025 |
| Cause dominante | cause `pct_cause_*` la plus élevée | `NULL` si aucun retard **ou** si toutes les causes valent 0 |

Retard moyen retenu pour le modèle : `retard_moyen_des_trains_en_retard_a_l_arrivee`, qui répond à « quand un train est en retard, de combien ? ». `retard_moyen_de_tous_les_trains_a_l_arrivee` est conservé à titre de complément.

Un aperçu calculé en fin de notebook confirme que les indicateurs sont calculables sur les données réelles.

## Anomalies à transformer en tests dbt (étape 6)

| # | Règle | Modèle | Sévérité proposée | Pourquoi |
| --- | --- | --- | --- | --- |
| 1 | `(mois, service, gare_depart, gare_arrivee)` unique | staging | error | Clé du grain : un doublon fausserait tout |
| 2 | Clés non nulles | staging | error | Idem |
| 3 | `service` dans (`NATIONAL`, `INTERNATIONAL`) après `upper()` | staging | error | La source écrit `National` / `International` |
| 4 | Somme des six causes = 100 ± 1 si `nb_trains_retard_arrivee > 0` | staging | warn | 89 lignes en échec, défaut de la source (2018-05 à 2018-08) |
| 5 | Causes entre 0 et 100 | staging | error | Toujours respecté aujourd'hui |
| 6 | `nb_annulations <= nb_trains_prevus` | staging | warn | 63 lignes en 2020 (confinement) |
| 7 | `nb_trains_retard_arrivee <= nb_trains_circules` | faits | warn | Respecté une fois les circulés bornés à 0, mais à surveiller |
| 8 | `retard_sup_60 <= retard_sup_30 <= retard_sup_15 <= retard_arrivee` | faits | warn | Environ 390 lignes en échec, dont 354 au T1 2025 |
| 9 | `nb_trains_retard_sup_30 >= 0` | staging | warn | 43 lignes négatives au T1 2025 |
| 10 | `retard_moyen_des_trains_en_retard_a_l_arrivee >= 0` | staging | warn | 2 lignes |
| 11 | `taux_ponctualite_arrivee` et `taux_annulation` entre 0 et 1 | faits | error | Garantis par les formules : un échec signale un bug de calcul |
| 12 | `cause_dominante` dans la liste des 6 causes | faits | error | Logique interne |
| 13 | `duree_moyenne_min > 0` si `nb_trains_prevus > 0` | staging | warn | Les durées à 0 n'apparaissent qu'avec 0 train prévu |
| 14 | Fraîcheur : chargement de moins de 35 / 45 jours | source | warn / error | Publication mensuelle |
| 15 | Nombre de lignes bronze du dernier fichier = nombre d'enregistrements CSV | bronze | error | Détecte un découpage des commentaires multilignes |

**Le point le plus important :** les tests du lab `nb_trains_retard_sup_60 <= ... <= sup_15` et `nb_trains_retard_arrivee <= nb_trains_circules` échoueraient en sévérité `error` sur les données réelles. Ils doivent passer en `warn`, car l'anomalie vient de la source et ne peut pas être corrigée.

## Impacts sur les étapes suivantes

- **Étape 2 (ingestion) :**
  - ajouter `'multiLine' = 'true'` et `'escape' = '"'` aux `FORMAT_OPTIONS` du `COPY INTO` ;
  - vérifier ensuite que la table compte 12 907 lignes par fichier ;
  - le BOM est déjà géré par `normalize_header` (`utf-8-sig`).
- **Étape 4 (staging) :**
  - utiliser les noms de colonnes réels ;
  - écarter les trois `commentaire_*` et la colonne « concurrencée par vol » ;
  - borner les trains circulés à 0.
- **Étape 5 (marts) :**
  - corriger `cause_dominante` pour le cas où toutes les causes valent 0 ;
  - garder le service dans `liaison_id` et documenter le cas Paris ↔ Barcelone ;
  - `dim_mois` peut démarrer en 2018-01 au lieu de 2015.
- **Étape 8 (dashboard) :** signaler dans une note que la part des retards de plus de 30 min n'est pas fiable au T1 2025, et qu'avril à juin 2020 sont atypiques (confinement).
