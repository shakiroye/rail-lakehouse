FROM astrocrpublic.azurecr.io/runtime:3.3-11

# dbt dans un virtualenv séparé : ses dépendances entrent souvent en conflit avec celles d'Airflow.
# Cosmos l'appelle via /usr/local/airflow/dbt_venv/bin/dbt (voir dags/rail_lakehouse_dag.py).
RUN python -m venv dbt_venv && \
    dbt_venv/bin/pip install --no-cache-dir "dbt-databricks==1.13.0"
