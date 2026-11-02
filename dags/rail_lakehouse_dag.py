"""
## Rail Lakehouse : open data SNCF -> bronze -> dbt (silver, gold)

Pipeline mensuel :

1. `ingest_bronze` télécharge la régularité TGV et la charge dans `bronze.regularite_tgv` (idempotent, COPY INTO).
2. `source_freshness` vérifie que le chargement est récent (`dbt source freshness`).
3. `dbt_transform` construit les modèles dbt en cible `prod` : une tâche Cosmos par modèle, suivie de ses tests.
"""
from datetime import datetime, timedelta
from pathlib import Path

from airflow.sdk import dag, task
from cosmos import DbtTaskGroup, ExecutionConfig, ProfileConfig, ProjectConfig, RenderConfig
from cosmos.constants import TestBehavior

DBT_DIR = Path("/usr/local/airflow/include/dbt")
DBT_EXE = "/usr/local/airflow/dbt_venv/bin/dbt"

profile_config = ProfileConfig(
    profile_name="rail_lakehouse",
    target_name="prod",
    profiles_yml_filepath=DBT_DIR / "profiles.yml",
)


@dag(
    schedule="0 6 5 * *",          # le 5 de chaque mois à 6 h, après la publication SNCF
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    default_args={"retries": 2, "retry_delay": timedelta(minutes=5)},
    tags=["sncf", "dbt", "databricks"],
    doc_md=__doc__,
)
def rail_lakehouse():

    @task
    def ingest_bronze() -> str:
        from include.ingestion.sncf import run
        return run("regularite_tgv")

    @task.bash
    def source_freshness() -> str:
        # Copie temporaire du projet (comme le fait Cosmos) : on n'écrit ni dbt_packages ni target
        # dans include/dbt, qui est un dossier monté en local et en lecture seule en déploiement
        return (f"tmp=$(mktemp -d) && cp -r {DBT_DIR}/. $tmp && cd $tmp && "
                f"{DBT_EXE} deps && {DBT_EXE} source freshness --profiles-dir . --target prod")

    dbt_transform = DbtTaskGroup(
        group_id="dbt_transform",
        project_config=ProjectConfig(DBT_DIR),
        profile_config=profile_config,
        execution_config=ExecutionConfig(dbt_executable_path=DBT_EXE),
        render_config=RenderConfig(
            test_behavior=TestBehavior.AFTER_EACH,
            # Les tests à plusieurs parents (réconciliations) deviennent des tâches à part,
            # lancées une fois tous leurs modèles construits
            should_detach_multiple_parents_tests=True,
        ),
        operator_args={"install_deps": True},
    )

    ingest_bronze() >> source_freshness() >> dbt_transform


rail_lakehouse()
