"""B2-D4-SS-7-2: live weather names its source and refreshes when the city changes."""
from app.router import weather_wellness as weather


def _fake(lat, lon):
    return {"temperature_c": 21 if lat > 35 else 16, "updated_at": f"2026-11-10T08:00+{int(lat)}"}


def test_snapshot_names_open_meteo_and_updated_at(monkeypatch):
    monkeypatch.setattr(weather, "fetch_open_meteo", _fake)
    data = weather.live_snapshot("北京")
    assert data["source"] == "Open-Meteo"
    assert data["updated_at"]
    assert data["city"] == "北京"
    assert data["latitude"] == weather.CITY_COORDS["北京"][0]


def test_city_change_uses_the_new_coordinates(monkeypatch):
    seen = []

    def fetch(lat, lon):
        seen.append((lat, lon))
        return _fake(lat, lon)

    monkeypatch.setattr(weather, "fetch_open_meteo", fetch)
    first = weather.live_snapshot("北京")
    second = weather.live_snapshot("上海")
    assert seen[0] != seen[1]
    assert first["summary"] != second["summary"]
    assert first["updated_at"] != second["updated_at"]
