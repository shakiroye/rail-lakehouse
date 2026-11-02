"""Ingestion de l'open data SNCF vers la couche bronze Databricks."""
import csv
import io
import logging
import os
import re
import unicodedata
from datetime import datetime, timezone

import requests
from databricks import sql
from databricks.sdk import WorkspaceClient

log = logging.getLogger(__name__)

SOURCES = {
    "regularite_tgv": "https://www.data.gouv.fr/api/1/datasets/r/91fe399d-cafa-4e72-8ba3-56d8717fdad4",
}
CATALOG = os.getenv("DATABRICKS_CATALOG", "workspace")
VOLUME = f"/Volumes/{CATALOG}/bronze/landing"
SEP = ";"
MIN_BYTES = 10_000  # garde-fou : un fichier plus petit est suspect


def to_snake(name: str) -> str:
    """'Gare de départ' -> 'gare_de_depart'."""
    name = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    return re.sub(r"[^0-9a-zA-Z]+", "_", name).strip("_").lower()


def normalize_header(raw: bytes, sep: str = SEP) -> bytes:
    """Renomme uniquement la ligne d'en-tête, le corps reste intact."""
    text = raw.decode("utf-8-sig")
    header, _, body = text.partition("\n")
    cols = [to_snake(c) for c in header.rstrip("\r").split(sep)]
    return (sep.join(cols) + "\n" + body).encode("utf-8")


def count_records(content: bytes, sep: str = SEP) -> int:
    """Nombre d'enregistrements CSV (hors en-tête), commentaires multilignes compris."""
    reader = csv.reader(io.StringIO(content.decode("utf-8-sig"), newline=""), delimiter=sep)
    next(reader)
    return sum(1 for _ in reader)


def download(url: str, timeout: int = 120) -> bytes:
    resp = requests.get(url, timeout=timeout)
    resp.raise_for_status()
    if len(resp.content) < MIN_BYTES:
        raise ValueError(f"Fichier trop petit : {len(resp.content)} octets")
    return resp.content


def upload_to_volume(content: bytes, source: str, run_date: str) -> str:
    w = WorkspaceClient(host=f"https://{os.environ['DATABRICKS_HOST']}",
                        token=os.environ["DATABRICKS_TOKEN"])
    path = f"{VOLUME}/{source}/{source}_{run_date}.csv"
    w.files.upload(path, io.BytesIO(content), overwrite=True)
    log.info("Déposé : %s (%d octets)", path, len(content))
    return path


def copy_into_bronze(source: str, path: str, expected_rows: int) -> None:
    table = f"{CATALOG}.bronze.{source}"
    with sql.connect(server_hostname=os.environ["DATABRICKS_HOST"],
                     http_path=os.environ["DATABRICKS_HTTP_PATH"],
                     access_token=os.environ["DATABRICKS_TOKEN"]) as conn:
        with conn.cursor() as cur:
            cur.execute(f"CREATE TABLE IF NOT EXISTS {table}")
            # multiLine + escape : les commentaires contiennent des retours à la ligne
            # et des guillemets doublés (voir docs/exploration.md, Q5)
            cur.execute(f"""
                COPY INTO {table}
                FROM (
                  SELECT *,
                         _metadata.file_path AS _source_file,
                         current_timestamp() AS _ingested_at
                  FROM '{VOLUME}/{source}/'
                )
                FILEFORMAT = CSV
                FORMAT_OPTIONS ('header' = 'true', 'sep' = '{SEP}', 'encoding' = 'UTF-8',
                                'multiLine' = 'true', 'quote' = '"', 'escape' = '"',
                                'inferSchema' = 'false', 'mergeSchema' = 'true')
                COPY_OPTIONS ('mergeSchema' = 'true')
            """)
            log.info("COPY INTO %s : %s", table, cur.fetchall())

            # Contrôle : le fichier du jour doit avoir autant de lignes en bronze que d'enregistrements CSV
            file_name = path.rsplit("/", 1)[-1]
            cur.execute(f"SELECT count(*) FROM {table} WHERE _source_file LIKE '%/{file_name}'")
            loaded = cur.fetchone()[0]
            if loaded != expected_rows:
                raise ValueError(f"{file_name} : {loaded} lignes en bronze, {expected_rows} attendues")
            log.info("Contrôle OK : %s -> %d lignes", file_name, loaded)


def run(source: str, run_date: str | None = None) -> str:
    run_date = run_date or datetime.now(timezone.utc).strftime("%Y%m%d")
    content = normalize_header(download(SOURCES[source]))
    path = upload_to_volume(content, source, run_date)
    copy_into_bronze(source, path, count_records(content))
    return path


if __name__ == "__main__":
    from dotenv import load_dotenv
    load_dotenv()
    logging.basicConfig(level=logging.INFO)
    logging.getLogger("databricks").setLevel(logging.WARNING)  # logs HTTP du connecteur trop verbeux
    run("regularite_tgv")
