"""体质接口同时接受拼音 id 和中文名。"""


def test_qiyu_chinese_name_matches_pinyin(client):
    pinyin = client.get("/api/v1/constitution/qiyu/foods")
    short = client.get("/api/v1/constitution/气郁/foods")
    full = client.get("/api/v1/constitution/气郁质/foods")
    assert pinyin.status_code == short.status_code == full.status_code == 200
    assert pinyin.json() == short.json() == full.json()
    missing = client.get("/api/v1/constitution/没有这种体质/foods")
    assert missing.status_code == 404
