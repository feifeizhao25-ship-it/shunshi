"""Run cross-channel isolation against production's database on every test run."""
import pytest

from .test_domestic_payment_recovery import (
    test_domestic_projection_serializes_with_store_restore as check_cross_channel,
)


@pytest.fixture()
def settings(settings, postgres_database_url):
    return settings.model_copy(update={"database_url": postgres_database_url})


@pytest.mark.parametrize("existing_entitlement", [False, True])
def test_postgres_cross_channel_isolation(client, auth_headers, existing_entitlement):
    check_cross_channel(client, auth_headers, existing_entitlement)
