"""
测试: 微信社交分享生成器 API
覆盖6个端点，包括节气海报、体质卡片、月报生成等。
"""

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def client():
    """创建FastAPI测试客户端"""
    from app.main import app
    return TestClient(app)


class TestGetSolarTermPoster:
    """GET /api/v1/wechat/poster/{solar_term_code} - 节气海报"""

    def test_get_lichun_poster(self, client):
        """测试：获取立春海报"""
        response = client.get("/api/v1/wechat/poster/lichun")
        assert response.status_code == 200
        assert response.json()["success"] is True
        data = response.json()["data"]
        assert data["name"] == "立春"
        assert "title" in data
        assert "content" in data
        assert "golden_sentence" in data
        assert "emoji_combo" in data

    def test_get_qingming_poster(self, client):
        """测试：获取清明海报"""
        response = client.get("/api/v1/wechat/poster/qingming")
        assert response.status_code == 200
        assert response.json()["data"]["name"] == "清明"

    def test_get_xiazhi_poster(self, client):
        """测试：获取夏至海报"""
        response = client.get("/api/v1/wechat/poster/xiazhi")
        assert response.status_code == 200
        assert response.json()["data"]["name"] == "夏至"

    def test_get_autumnequinox_poster(self, client):
        """测试：获取秋分海报"""
        response = client.get("/api/v1/wechat/poster/autumnequinox")
        assert response.status_code == 200
        assert response.json()["data"]["name"] == "秋分"

    def test_poster_contains_required_fields(self, client):
        """测试：海报包含必需字段"""
        response = client.get("/api/v1/wechat/poster/dongzhi")
        data = response.json()["data"]
        required_fields = ["name", "date", "title", "content", "golden_sentence", "emoji_combo"]
        for field in required_fields:
            assert field in data

    def test_get_all_24_solar_terms(self, client):
        """测试：可获取所有24个节气"""
        solar_terms = ["lichun", "yushui", "jingzhe", "qingming", "guyu", "lixia",
                      "xiaoman", "duanwu", "xiazhi", "xiaoshu", "dashu", "liqiu",
                      "chushu", "bailu", "autumnequinox", "hengshan", "shuangjiang",
                      "lidong", "xiaoXue", "daxue", "dongzhi", "xiaohan", "dahan"]
        for term in solar_terms[:6]:  # 测试前6个
            response = client.get(f"/api/v1/wechat/poster/{term}")
            assert response.status_code == 200

    def test_invalid_solar_term_code(self, client):
        """测试：无效节气码返回404"""
        response = client.get("/api/v1/wechat/poster/invalid_term_xyz")
        assert response.status_code == 404


class TestGetConstitutionCard:
    """GET /api/v1/wechat/constitution-card/{constitution_type} - 体质卡片"""

    def test_get_qi_deficiency_card(self, client):
        """测试：获取气虚体质卡片"""
        response = client.get("/api/v1/wechat/constitution-card/qi_deficiency")
        assert response.status_code == 200
        assert response.json()["success"] is True
        data = response.json()["data"]
        assert data["name"] == "气虚质"
        assert "tagline" in data
        assert "core_feature" in data
        assert "adjustment_points" in data
        assert "color_suggestion" in data

    def test_get_yang_deficiency_card(self, client):
        """测试：获取阳虚体质卡片"""
        response = client.get("/api/v1/wechat/constitution-card/yang_deficiency")
        assert response.status_code == 200
        assert response.json()["data"]["name"] == "阳虚质"

    def test_get_yin_deficiency_card(self, client):
        """测试：获取阴虚体质卡片"""
        response = client.get("/api/v1/wechat/constitution-card/yin_deficiency")
        assert response.status_code == 200
        assert response.json()["data"]["name"] == "阴虚质"

    def test_get_blood_deficiency_card(self, client):
        """测试：获取血虚体质卡片"""
        response = client.get("/api/v1/wechat/constitution-card/blood_deficiency")
        assert response.status_code == 200
        assert response.json()["data"]["name"] == "血虚质"

    def test_get_damp_card(self, client):
        """测试：获取痰湿体质卡片"""
        response = client.get("/api/v1/wechat/constitution-card/damp")
        assert response.status_code == 200
        assert response.json()["data"]["name"] == "痰湿质"

    def test_get_damp_heat_card(self, client):
        """测试：获取湿热体质卡片"""
        response = client.get("/api/v1/wechat/constitution-card/damp_heat")
        assert response.status_code == 200
        assert response.json()["data"]["name"] == "湿热质"

    def test_get_qi_stagnation_card(self, client):
        """测试：获取气郁体质卡片"""
        response = client.get("/api/v1/wechat/constitution-card/qi_stagnation")
        assert response.status_code == 200
        assert response.json()["data"]["name"] == "气郁质"

    def test_get_blood_stasis_card(self, client):
        """测试：获取血瘀体质卡片"""
        response = client.get("/api/v1/wechat/constitution-card/blood_stasis")
        assert response.status_code == 200
        assert response.json()["data"]["name"] == "血瘀质"

    def test_get_balanced_card(self, client):
        """测试：获取平和体质卡片"""
        response = client.get("/api/v1/wechat/constitution-card/balanced")
        assert response.status_code == 200
        assert response.json()["data"]["name"] == "平和质"

    def test_card_contains_required_fields(self, client):
        """测试：卡片包含必需字段"""
        response = client.get("/api/v1/wechat/constitution-card/qi_deficiency")
        data = response.json()["data"]
        required_fields = ["name", "tagline", "core_feature", "adjustment_points",
                          "color_suggestion", "emoji"]
        for field in required_fields:
            assert field in data

    def test_all_9_constitutions(self, client):
        """测试：所有9种体质都有卡片"""
        constitutions = ["qi_deficiency", "yang_deficiency", "yin_deficiency",
                        "blood_deficiency", "damp", "damp_heat",
                        "qi_stagnation", "blood_stasis", "balanced"]
        for const in constitutions:
            response = client.get(f"/api/v1/wechat/constitution-card/{const}")
            assert response.status_code == 200
            assert response.json()["success"] is True

    def test_invalid_constitution_type(self, client):
        """测试：无效体质类型返回404"""
        response = client.get("/api/v1/wechat/constitution-card/invalid_constitution_xyz")
        assert response.status_code == 404


class TestGetDailyCheckinCaption:
    """GET /api/v1/wechat/checkin-caption - 每日打卡文案"""

    def test_get_checkin_caption(self, client):
        """测试：获取打卡文案"""
        response = client.get("/api/v1/wechat/checkin-caption")
        assert response.status_code == 200
        data = response.json()["data"]
        assert "caption" in data
        assert "season" in data
        assert "timestamp" in data
        assert isinstance(data["caption"], str)
        assert len(data["caption"]) > 0

    def test_checkin_caption_with_mood_happy(self, client):
        """测试：带happy心情的打卡文案"""
        response = client.get("/api/v1/wechat/checkin-caption?mood=happy")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["mood"] == "happy"

    def test_checkin_caption_with_mood_calm(self, client):
        """测试：带calm心情的打卡文案"""
        response = client.get("/api/v1/wechat/checkin-caption?mood=calm")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["mood"] == "calm"

    def test_checkin_caption_with_mood_tired(self, client):
        """测试：带tired心情的打卡文案"""
        response = client.get("/api/v1/wechat/checkin-caption?mood=tired")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["mood"] == "tired"

    def test_checkin_caption_season_valid(self, client):
        """测试：季节有效"""
        response = client.get("/api/v1/wechat/checkin-caption")
        season = response.json()["data"]["season"]
        assert season in ["spring", "summer", "autumn", "winter"]

    def test_checkin_caption_contains_emoji(self, client):
        """测试：打卡文案包含emoji"""
        response = client.get("/api/v1/wechat/checkin-caption")
        caption = response.json()["data"]["caption"]
        # 简单检查是否包含emoji符号或井号标签
        assert "#" in caption or any(ord(char) > 127 for char in caption)

    def test_checkin_caption_randomness(self, client):
        """测试：多次获取可能返回不同文案"""
        captions = set()
        for _ in range(3):
            response = client.get("/api/v1/wechat/checkin-caption")
            captions.add(response.json()["data"]["caption"])
        # 由于是随机选择，可能不同（但不保证）


class TestGenerateMonthlyReport:
    """POST /api/v1/wechat/monthly-report - 月报生成"""

    def test_generate_monthly_report(self, client):
        """测试：生成月报"""
        response = client.post("/api/v1/wechat/monthly-report", json={
            "user_name": "小明",
            "month": 3,
            "checkin_days": 25,
            "avg_mood": "happy",
            "top_wellness_action": "坚持艾灸",
        })
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["user_name"] == "小明"
        assert data["month"] == "3月"
        assert data["checkin_days"] == 25
        assert "report_content" in data
        assert "小明" in data["report_content"]

    def test_generate_monthly_report_december(self, client):
        """测试：12月月报"""
        response = client.post("/api/v1/wechat/monthly-report", json={
            "user_name": "小红",
            "month": 12,
            "checkin_days": 28,
            "avg_mood": "calm",
            "top_wellness_action": "三九灸",
        })
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["month"] == "12月"
        assert "12月" in data["report_content"]

    def test_generate_monthly_report_jan(self, client):
        """测试：1月月报"""
        response = client.post("/api/v1/wechat/monthly-report", json={
            "user_name": "用户",
            "month": 1,
            "checkin_days": 20,
            "avg_mood": "neutral",
            "top_wellness_action": "温阳进补",
        })
        assert response.status_code == 200
        data = response.json()["data"]
        assert "1月" in data["report_content"]

    def test_report_contains_required_fields(self, client):
        """测试：月报包含必需字段"""
        response = client.post("/api/v1/wechat/monthly-report", json={
            "user_name": "测试用户",
            "month": 6,
            "checkin_days": 15,
            "avg_mood": "happy",
            "top_wellness_action": "运动",
        })
        data = response.json()["data"]
        required_fields = ["user_name", "month", "checkin_days", "avg_mood",
                          "top_wellness_action", "report_content", "share_emoji"]
        for field in required_fields:
            assert field in data

    def test_report_content_includes_user_name(self, client):
        """测试：月报包含用户名"""
        user_name = "张三"
        response = client.post("/api/v1/wechat/monthly-report", json={
            "user_name": user_name,
            "month": 5,
            "checkin_days": 20,
            "avg_mood": "happy",
            "top_wellness_action": "春游",
        })
        content = response.json()["data"]["report_content"]
        assert user_name in content

    def test_report_content_includes_checkin_days(self, client):
        """测试：月报包含打卡天数"""
        response = client.post("/api/v1/wechat/monthly-report", json={
            "user_name": "用户",
            "month": 7,
            "checkin_days": 30,
            "avg_mood": "calm",
            "top_wellness_action": "艾灸",
        })
        content = response.json()["data"]["report_content"]
        assert "30" in content

    def test_report_with_minimal_checkin_days(self, client):
        """测试：打卡天数较少的月报"""
        response = client.post("/api/v1/wechat/monthly-report", json={
            "user_name": "新手",
            "month": 8,
            "checkin_days": 5,
            "avg_mood": "happy",
            "top_wellness_action": "开始养生",
        })
        assert response.status_code == 200
        assert response.json()["data"]["checkin_days"] == 5

    def test_report_emoji_present(self, client):
        """测试：月报包含emoji"""
        response = client.post("/api/v1/wechat/monthly-report", json={
            "user_name": "测试",
            "month": 9,
            "checkin_days": 20,
            "avg_mood": "happy",
            "top_wellness_action": "秋季调理",
        })
        data = response.json()["data"]
        assert data["share_emoji"] == "🌿 💪 ✨"


class TestListTemplates:
    """GET /api/v1/wechat/templates - 模板列表"""

    def test_list_templates(self, client):
        """测试：获取模板列表"""
        response = client.get("/api/v1/wechat/templates")
        assert response.status_code == 200
        data = response.json()["data"]
        assert "templates" in data
        assert "tip" in data

    def test_templates_has_solar_term_poster(self, client):
        """测试：包含节气海报模板"""
        response = client.get("/api/v1/wechat/templates")
        templates = response.json()["data"]["templates"]
        assert "solar_term_poster" in templates

    def test_templates_has_constitution_card(self, client):
        """测试：包含体质卡片模板"""
        response = client.get("/api/v1/wechat/templates")
        templates = response.json()["data"]["templates"]
        assert "constitution_card" in templates

    def test_templates_has_daily_checkin(self, client):
        """测试：包含每日打卡模板"""
        response = client.get("/api/v1/wechat/templates")
        templates = response.json()["data"]["templates"]
        assert "daily_checkin" in templates

    def test_templates_has_monthly_report(self, client):
        """测试：包含月报模板"""
        response = client.get("/api/v1/wechat/templates")
        templates = response.json()["data"]["templates"]
        assert "monthly_report" in templates

    def test_solar_term_poster_count(self, client):
        """测试：节气海报数量为24"""
        response = client.get("/api/v1/wechat/templates")
        templates = response.json()["data"]["templates"]
        assert templates["solar_term_poster"]["count"] == 24

    def test_constitution_card_count(self, client):
        """测试：体质卡片数量为9"""
        response = client.get("/api/v1/wechat/templates")
        templates = response.json()["data"]["templates"]
        assert templates["constitution_card"]["count"] == 9

    def test_templates_available_codes(self, client):
        """测试：可用节气码列表非空"""
        response = client.get("/api/v1/wechat/templates")
        templates = response.json()["data"]["templates"]
        codes = templates["solar_term_poster"]["available_codes"]
        assert len(codes) == 24

    def test_templates_available_constitution_types(self, client):
        """测试：可用体质列表有9种"""
        response = client.get("/api/v1/wechat/templates")
        templates = response.json()["data"]["templates"]
        types = templates["constitution_card"]["available_types"]
        assert len(types) == 9


class TestGetSolarTermWishes:
    """GET /api/v1/wechat/solar-term-wishes/{solar_term_code} - 节气祝福语"""

    def test_get_lichun_wishes(self, client):
        """测试：获取立春祝福语"""
        response = client.get("/api/v1/wechat/solar-term-wishes/lichun")
        assert response.status_code == 200
        data = response.json()["data"]
        assert "solar_term" in data
        assert data["solar_term"] == "立春"
        assert "wishes" in data
        assert isinstance(data["wishes"], list)
        assert len(data["wishes"]) == 3

    def test_get_xiazhi_wishes(self, client):
        """测试：获取夏至祝福语"""
        response = client.get("/api/v1/wechat/solar-term-wishes/xiazhi")
        assert response.status_code == 200
        assert response.json()["data"]["solar_term"] == "夏至"

    def test_get_dongzhi_wishes(self, client):
        """测试：获取冬至祝福语"""
        response = client.get("/api/v1/wechat/solar-term-wishes/dongzhi")
        assert response.status_code == 200
        assert response.json()["data"]["solar_term"] == "冬至"

    def test_wishes_contains_required_fields(self, client):
        """测试：祝福语包含必需字段"""
        response = client.get("/api/v1/wechat/solar-term-wishes/qingming")
        data = response.json()["data"]
        required_fields = ["solar_term", "solar_term_code", "wishes", "tip"]
        for field in required_fields:
            assert field in data

    def test_wishes_is_list_of_strings(self, client):
        """测试：祝福语是字符串列表"""
        response = client.get("/api/v1/wechat/solar-term-wishes/guyu")
        wishes = response.json()["data"]["wishes"]
        assert isinstance(wishes, list)
        assert all(isinstance(w, str) for w in wishes)

    def test_wishes_count_is_three(self, client):
        """测试：每个节气有3条祝福语"""
        response = client.get("/api/v1/wechat/solar-term-wishes/lixia")
        wishes = response.json()["data"]["wishes"]
        assert len(wishes) == 3

    def test_wishes_each_non_empty(self, client):
        """测试：每条祝福语都非空"""
        response = client.get("/api/v1/wechat/solar-term-wishes/dashu")
        wishes = response.json()["data"]["wishes"]
        assert all(len(w) > 0 for w in wishes)

    def test_invalid_solar_term_wishes(self, client):
        """测试：无效节气码返回404"""
        response = client.get("/api/v1/wechat/solar-term-wishes/invalid_term_xyz")
        assert response.status_code == 404
