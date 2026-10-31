"""The international Flutter clients carry a copy of the crisis helplines; it must match the backend.

Backend source of truth: app/safety/crisis_resources.py. Clients: ios-global and android-global
lib/core/safety/crisis_resources.dart. If someone changes a number in one place only, this fails.
"""

import pathlib

from app.safety.crisis_resources import DIRECTORY_URL, RESOURCES

ROOT = pathlib.Path(__file__).resolve().parents[2]
CLIENTS = [ROOT / "ios-global/lib/core/safety/crisis_resources.dart", ROOT / "android-global/lib/core/safety/crisis_resources.dart"]


def test_clients_match_backend_resources():
    for client in CLIENTS:
        text = client.read_text(encoding="utf-8")
        assert DIRECTORY_URL in text, client
        for region, res in RESOURCES.items():
            for field in (res.name, res.contact, res.emergency, res.source_url):
                assert f"'{field}'" in text, f"{client.name} ({client.parent.parent.parent.name}): {region} {field!r} differs from backend"
