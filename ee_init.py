"""Earth Engine init from the local gcloud login (Colab/notebook auth is blocked on this project)."""
import os
import subprocess

import ee
import google.oauth2.credentials

PROJECT = os.environ.get("EE_PROJECT", "superagentduper")
ACCOUNT = os.environ.get("EE_ACCOUNT", "")  # gcloud account; empty = active one


def init(project: str = PROJECT) -> None:
    tok = subprocess.check_output(
        ["gcloud", "auth", "print-access-token", *(["--account", ACCOUNT] if ACCOUNT else [])]
    ).decode().strip()
    ee.Initialize(google.oauth2.credentials.Credentials(tok), project=project)
