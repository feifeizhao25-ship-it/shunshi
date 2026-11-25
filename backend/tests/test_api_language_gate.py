"""共5：国内接口不返回整句英文校验错误，国际接口的这几处不返回汉字。

白名单：国内响应里的英文字段名（plan、email）可以留下。
拦住的是整句英文校验（Input should、Not authenticated、string_too_short）。
"""
import re

import pytest

CJK = re.compile(r"[\u4e00-\u9fff]")
ENGLISH_LEAK = re.compile(
    r"Input should|Not authenticated|string_too_short|Field required|value is not a valid",
    re.I,
)
GLOBAL = {"Accept-Language": "en-US", "X-App-Market": "global"}


def test_domestic_validation_error_is_chinese(client):
    response = client.post("/api/v1/auth/register", json={})
    assert response.status_code == 422, response.text
    assert CJK.search(response.text)
    assert not ENGLISH_LEAK.search(response.text)


def test_international_validation_error_has_no_chinese(client):
    response = client.post("/api/v1/auth/register", json={}, headers=GLOBAL)
    assert response.status_code == 422, response.text
    assert not CJK.search(response.text)
    assert not ENGLISH_LEAK.search(response.text)


def test_international_subscription_plan_name_is_english(client, auth_headers):
    response = client.get("/api/v1/subscription/status", headers={**auth_headers, **GLOBAL})
    assert response.status_code == 200, response.text
    plan_name = response.json()["data"]["plan_name"]
    assert plan_name == "Free"
    assert not CJK.search(plan_name)


def test_domestic_subscription_plan_name_stays_chinese(client, auth_headers):
    response = client.get("/api/v1/subscription/status", headers=auth_headers)
    assert response.status_code == 200, response.text
    assert response.json()["data"]["plan_name"] == "免费版"


def test_international_constitution_names_have_no_chinese(client):
    response = client.get("/api/v1/constitution/", headers=GLOBAL)
    assert response.status_code == 200, response.text
    names = response.json()["data"]
    assert names
    assert not CJK.search(str(names))
    assert any(item["name"] == "Balanced Constitution" for item in names)


def test_domestic_constitution_names_stay_chinese(client):
    response = client.get("/api/v1/constitution/")
    assert response.status_code == 200, response.text
    assert any(item["name"] == "平和质" for item in response.json()["data"])


@pytest.mark.parametrize("path", ["/api/v1/constitution/types"])
def test_international_constitution_types_have_no_chinese(client, path):
    response = client.get(path, headers=GLOBAL)
    assert response.status_code == 200, response.text
    assert not CJK.search(response.text)
