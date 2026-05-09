"""顺时 - 儿童养护测试"""
import pytest


class TestChildAgeGroups:
    def test_age_groups_returns_200(self, client):
        response = client.get("/api/v1/child-wellness/age-groups")
        assert response.status_code == 200

    def test_age_groups_has_groups(self, client):
        data = client.get("/api/v1/child-wellness/age-groups").json()
        assert "data" in data
        assert data["success"] is True


class TestChildSeasonalCare:
    def test_seasonal_spring_returns_200(self, client):
        response = client.get("/api/v1/child-wellness/seasonal-care/spring")
        assert response.status_code == 200

    def test_seasonal_winter_returns_200(self, client):
        response = client.get("/api/v1/child-wellness/seasonal-care/winter")
        assert response.status_code == 200


class TestChildCommonIssues:
    def test_common_issues_returns_200(self, client):
        response = client.get("/api/v1/child-wellness/common-issues")
        assert response.status_code == 200

    def test_common_issues_has_list(self, client):
        data = client.get("/api/v1/child-wellness/common-issues").json()
        assert "data" in data


class TestChildIssueDetail:
    def test_issue_detail_returns_200(self, client):
        response = client.get("/api/v1/child-wellness/common-issues/cold")
        assert response.status_code == 200


class TestChildDietGuide:
    def test_diet_guide_returns_200(self, client):
        response = client.get("/api/v1/child-wellness/diet-guide")
        assert response.status_code == 200


class TestChildMassageGuide:
    def test_massage_guide_returns_200(self, client):
        response = client.get("/api/v1/child-wellness/massage-guide")
        assert response.status_code == 200

    def test_massage_guide_has_data(self, client):
        data = client.get("/api/v1/child-wellness/massage-guide").json()
        assert data["success"] is True
