import pytest
from include.ingestion.sncf import count_records, download, normalize_header, to_snake


@pytest.mark.parametrize("raw, attendu", [
    ("Gare de départ", "gare_de_depart"),
    ("Gare d'arrivée", "gare_d_arrivee"),
    ("nb_train_prevu", "nb_train_prevu"),
    ("Prct cause (externe)", "prct_cause_externe"),
    ("Nombre trains en retard > 15min", "nombre_trains_en_retard_15min"),
])
def test_to_snake(raw, attendu):
    assert to_snake(raw) == attendu


def test_normalize_header_ne_touche_pas_au_corps():
    raw = "﻿Gare de départ;Date\nPARIS LYON;2024-01\n".encode()
    assert normalize_header(raw) == b"gare_de_depart;date\nPARIS LYON;2024-01\n"


def test_count_records_gere_les_commentaires_multilignes():
    raw = 'date;commentaire\n2018-01;"Tempête\nle 1er ; ""Carmen"""\n2018-02;\n'.encode()
    assert count_records(raw) == 2


def test_download_refuse_un_fichier_vide():
    # requests-mock n'est pas dans l'image Airflow : test ignoré par "astro dev pytest", exécuté en local et en CI
    requests_mock = pytest.importorskip("requests_mock")
    with requests_mock.Mocker() as m:
        m.get("https://exemple.fr/f.csv", content=b"a;b\n")
        with pytest.raises(ValueError):
            download("https://exemple.fr/f.csv")
