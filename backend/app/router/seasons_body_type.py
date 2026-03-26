"""
SEASONS Body Type Assessment API
GET  /api/v1/seasons/body-type/types
GET  /api/v1/seasons/body-type/types/{code}
GET  /api/v1/seasons/body-type/questions
POST /api/v1/seasons/body-type/assessment
GET  /api/v1/seasons/body-type/result
GET  /api/v1/seasons/body-type/plan
"""
from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Dict
import psycopg2
import psycopg2.extras
import uuid

router = APIRouter(prefix="/api/v1/seasons", tags=["seasons-body-type"])
DB_CONFIG = {
    "host": "127.0.0.1",
    "dbname": "shunshi",
    "user": "shunshi",
    "password": "shunshi123",
}

def get_conn():
    return psycopg2.connect(**DB_CONFIG, cursor_factory=psycopg2.extras.RealDictCursor)

# In-memory user body type results (production would use JWT auth + DB)
_user_results: Dict[str, dict] = {}


class AssessmentSubmit(BaseModel):
    user_id: str
    answers: Dict[str, int]  # question_key -> answer value (1-5)


@router.get("/body-type/types")
async def list_body_types():
    """List all 7 body types"""
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("SELECT code, name, tagline, description, characteristics, strengths, challenges, color_code, icon_url FROM body_types")
        rows = cur.fetchall()
        return [dict(r) for r in rows]
    finally:
        cur.close(); conn.close()


@router.get("/body-type/types/{code}")
async def get_body_type(code: str):
    """Get detailed body type info"""
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("SELECT * FROM body_types WHERE code = %s", (code,))
        r = cur.fetchone()
        if not r:
            raise HTTPException(status_code=404, detail="Body type not found")
        return dict(r)
    finally:
        cur.close(); conn.close()


@router.get("/body-type/questions")
async def get_questions():
    """Get body type assessment questions"""
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("SELECT id, question_key, question_text, options, category, sequence FROM body_type_questions WHERE is_active = true ORDER BY sequence")
        rows = cur.fetchall()
        return [dict(r) for r in rows]
    finally:
        cur.close(); conn.close()


@router.post("/body-type/assessment")
async def submit_assessment(body: AssessmentSubmit):
    """Submit body type assessment and get result"""
    conn = get_conn()
    cur = conn.cursor()
    try:
        # Get all questions and body types
        cur.execute("SELECT question_key, options FROM body_type_questions WHERE is_active = true")
        questions = {r["question_key"]: r["options"] for r in cur.fetchall()}

        cur.execute("SELECT code, name, nutrition_recommendations, movement_recommendations, sleep_recommendations FROM body_types")
        body_types = {r["code"]: r for r in cur.fetchall()}

        # Score each body type
        scores = {}
        for bt_code, bt_data in body_types.items():
            scores[bt_code] = 0

        for q_key, answer in body.answers.items():
            if q_key not in questions:
                continue
            options = questions[q_key]
            for opt in options:
                weights = opt.get("types_weight", {})
                for bt_code, weight in weights.items():
                    if bt_code in scores:
                        scores[bt_code] += weight * answer

        # Sort by score
        sorted_types = sorted(scores.items(), key=lambda x: x[1], reverse=True)
        primary = sorted_types[0][0]
        secondary = sorted_types[1][0] if len(sorted_types) > 1 else None

        bt = body_types[primary]

        result = {
            "primary_type": primary,
            "secondary_type": secondary,
            "scores": scores,
            "body_type": {
                "code": bt["code"],
                "name": bt["name"],
                "description": bt.get("description", ""),
                "nutrition_recommendations": bt.get("nutrition_recommendations", {}),
                "movement_recommendations": bt.get("movement_recommendations", {}),
                "sleep_recommendations": bt.get("sleep_recommendations", {}),
            }
        }

        # Save result
        _user_results[body.user_id] = result

        # Persist to DB
        record_id = str(uuid.uuid4())
        cur.execute("""
            INSERT INTO body_type_test_records (id, user_id, answers, scores, primary_type, secondary_type, created_at)
            VALUES (%s, %s, %s, %s, %s, %s, NOW())
        """, (record_id, body.user_id,
              str(body.answers), str(scores), primary, secondary))
        conn.commit()

        return result
    finally:
        cur.close(); conn.close()


@router.get("/body-type/result")
async def get_result(user_id: str = Query(...)):
    """Get user's latest body type result"""
    if user_id in _user_results:
        return _user_results[user_id]
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT primary_type, secondary_type, scores, created_at
            FROM body_type_test_records
            WHERE user_id = %s
            ORDER BY created_at DESC LIMIT 1
        """, (user_id,))
        r = cur.fetchone()
        if not r:
            raise HTTPException(status_code=404, detail="No assessment result found")
        return dict(r)
    finally:
        cur.close(); conn.close()


@router.get("/body-type/plan")
async def get_body_type_plan(user_id: str = Query(...), season: str = Query("spring")):
    """Get personalized wellness plan based on body type and current season"""
    if user_id not in _user_results:
        raise HTTPException(status_code=404, detail="Please complete body type assessment first")
    result = _user_results[user_id]
    bt_code = result["primary_type"]
    conn = get_conn()
    cur = conn.cursor()
    try:
        # Get seasonal adjustments for this body type
        cur.execute("SELECT seasonal_adjustments, nutrition_recommendations FROM body_types WHERE code = %s", (bt_code,))
        r = cur.fetchone()
        if not r:
            raise HTTPException(status_code=404, detail="Body type not found")
        adj = r.get("seasonal_adjustments") or {}
        return {
            "body_type": bt_code,
            "current_season": season,
            "nutrition": r.get("nutrition_recommendations") or {},
            "seasonal_adjustment": adj.get(season, {}),
            "recommendations": result,
        }
    finally:
        cur.close(); conn.close()
