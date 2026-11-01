USE CATALOG workspace;
CREATE SCHEMA IF NOT EXISTS bronze COMMENT 'Données brutes, telles que
reçues';
CREATE SCHEMA IF NOT EXISTS silver COMMENT 'Données nettoyées et typées (dbt
staging)';
CREATE SCHEMA IF NOT EXISTS gold COMMENT 'Modèle en étoile et marts (dbt
marts)';
-- Zone de dépôt des fichiers bruts
CREATE VOLUME IF NOT EXISTS bronze.landing;