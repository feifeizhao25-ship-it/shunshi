"""
顺时 — 卡路里追踪 API (shunshi-calorie-tracker)
食物卡路里查询、每日摄入记录、营养分析 (PostgreSQL backed)
"""
import uuid
from datetime import datetime, date
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.db.database import get_db
from app.models.wellness_tracking import MealLog, CalorieGoal

router = APIRouter(prefix="/api/v1/calorie-tracker", tags=["calorie-tracker"])

# Static food database (production would use a real DB table)
_FOODS = {
    "rice": {"food_id": "rice", "name": "米饭", "name_en": "Rice",
             "calories_per_100g": 116, "protein_g": 2.6, "carbs_g": 25.9, "fat_g": 0.3,
             "tcm_nature": "甘、平", "tcm_function": "补中益气，健脾和胃"},
    "tofu": {"food_id": "tofu", "name": "豆腐", "name_en": "Tofu",
             "calories_per_100g": 76, "protein_g": 8.1, "carbs_g": 1.9, "fat_g": 4.8,
             "tcm_nature": "甘、凉", "tcm_function": "清热润燥，益气和中"},
    "chicken": {"food_id": "chicken", "name": "鸡肉", "name_en": "Chicken",
                "calories_per_100g": 167, "protein_g": 19.3, "carbs_g": 0, "fat_g": 9.4,
                "tcm_nature": "甘、温", "tcm_function": "温中益气，补精填髓"},
    "spinach": {"food_id": "spinach", "name": "菠菜", "name_en": "Spinach",
                "calories_per_100g": 28, "protein_g": 2.9, "carbs_g": 3.6, "fat_g": 0.4,
                "tcm_nature": "甘、凉", "tcm_function": "养血止血，滋阴平肝"},
    "yam": {"food_id": "yam", "name": "山药", "name_en": "Chinese Yam",
            "calories_per_100g": 56, "protein_g": 1.9, "carbs_g": 12.4, "fat_g": 0.2,
            "tcm_nature": "甘、平", "tcm_function": "补脾养胃，生津益肺，补肾涩精"},
    "lotus_root": {"food_id": "lotus_root", "name": "莲藕", "name_en": "Lotus Root",
                   "calories_per_100g": 73, "protein_g": 1.9, "carbs_g": 16.4, "fat_g": 0.2,
                   "tcm_nature": "甘、寒（生）/ 甘、温（熟）",
                   "tcm_function": "生用清热凉血，熟用健脾开胃"},
    "goji": {"food_id": "goji", "name": "枸杞", "name_en": "Goji Berry",
             "calories_per_100g": 258, "protein_g": 13.9, "carbs_g": 64.1, "fat_g": 1.5,
             "tcm_nature": "甘、平", "tcm_function": "滋补肝肾，益精明目"},
    "red_date": {"food_id": "red_date", "name": "红枣", "name_en": "Red Date",
                 "calories_per_100g": 264, "protein_g": 3.2, "carbs_g": 67.8, "fat_g": 0.5,
                 "tcm_nature": "甘、温", "tcm_function": "补中益气，养血安神"},
    "black_sesame": {"food_id": "black_sesame", "name": "黑芝麻", "name_en": "Black Sesame",
                     "calories_per_100g": 559, "protein_g": 19.1, "carbs_g": 24.0, "fat_g": 46.1,
                     "tcm_nature": "甘、平", "tcm_function": "补肝肾，益精血，润肠燥"},
    "walnuts": {"food_id": "walnuts", "name": "核桃", "name_en": "Walnut",
                "calories_per_100g": 646, "protein_g": 14.9, "carbs_g": 19.1, "fat_g": 58.8,
                "tcm_nature": "甘、温", "tcm_function": "补肾温肺，润肠通便"},
}


class FoodItem(BaseModel):
    food_id: str
    amount_g: float = Field(..., gt=0)


class MealLogIn(BaseModel):
    user_id: str
    meal_type: str = Field(..., pattern="^(breakfast|lunch|dinner|snack)$")
    foods: List[FoodItem] = []
    date: Optional[str] = None


class CalorieGoalIn(BaseModel):
    user_id: str
    daily_calories: int = Field(..., ge=500, le=5000)


def _calc_nutrition(food_id: str, amount_g: float) -> dict:
    food = _FOODS.get(food_id)
    if not food:
        return {"food_id": food_id, "calories": 0, "protein_g": 0, "carbs_g": 0, "fat_g": 0}
    ratio = amount_g / 100
    return {
        "food_id": food_id,
        "food_name": food["name"],
        "amount_g": amount_g,
        "calories": round(food["calories_per_100g"] * ratio, 1),
        "protein_g": round(food["protein_g"] * ratio, 1),
        "carbs_g": round(food["carbs_g"] * ratio, 1),
        "fat_g": round(food["fat_g"] * ratio, 1),
    }


@router.get("/foods/search", summary="搜索食物")
def search_foods(q: str = Query(..., min_length=1)):
    results = [
        f for f in _FOODS.values()
        if q in f["name"] or q.lower() in f.get("name_en", "").lower()
    ]
    return {"success": True, "data": {"results": results, "total": len(results)}}


@router.get("/foods/{food_id}", summary="食物营养详情")
def get_food(food_id: str):
    if food_id not in _FOODS:
        raise HTTPException(status_code=404, detail="食物不存在")
    return {"success": True, "data": _FOODS[food_id]}


@router.post("/log", summary="记录饮食")
def log_meal(body: MealLogIn, db: Session = Depends(get_db)):
    log_date = date.fromisoformat(body.date) if body.date else date.today()

    # Compute nutrition totals
    food_details = [_calc_nutrition(f.food_id, f.amount_g) for f in body.foods]
    total_cal = sum(f["calories"] for f in food_details)
    total_protein = sum(f["protein_g"] for f in food_details)
    total_carbs = sum(f["carbs_g"] for f in food_details)
    total_fat = sum(f["fat_g"] for f in food_details)

    entry = MealLog(
        id=uuid.uuid4(),
        user_id=body.user_id,
        meal_type=body.meal_type,
        foods=[{"food_id": f.food_id, "amount_g": f.amount_g} for f in body.foods],
        total_calories=total_cal,
        total_protein_g=total_protein,
        total_carbs_g=total_carbs,
        total_fat_g=total_fat,
        date=log_date,
        logged_at=datetime.now(),
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)

    return {
        "success": True,
        "data": {
            "log_id": str(entry.id),
            "meal_type": body.meal_type,
            "foods": food_details,
            "totals": {
                "calories": total_cal,
                "protein_g": total_protein,
                "carbs_g": total_carbs,
                "fat_g": total_fat,
            },
            "date": log_date.isoformat(),
        }
    }


@router.get("/today", summary="今日摄入统计")
def today_intake(user_id: str = Query(...), db: Session = Depends(get_db)):
    today = date.today()
    logs = db.query(MealLog).filter(
        MealLog.user_id == user_id,
        MealLog.date == today,
    ).order_by(MealLog.logged_at.asc()).all()

    total_cal = sum(l.total_calories for l in logs)
    total_protein = sum(l.total_protein_g for l in logs)
    total_carbs = sum(l.total_carbs_g for l in logs)
    total_fat = sum(l.total_fat_g for l in logs)

    goal_row = db.query(CalorieGoal).filter(CalorieGoal.user_id == user_id).first()
    goal_cal = goal_row.daily_calories if goal_row else 2000

    return {
        "success": True,
        "data": {
            "date": today.isoformat(),
            "meals": [
                {
                    "log_id": str(l.id),
                    "meal_type": l.meal_type,
                    "calories": l.total_calories,
                    "logged_at": l.logged_at.isoformat(),
                }
                for l in logs
            ],
            "totals": {
                "calories": round(total_cal, 1),
                "protein_g": round(total_protein, 1),
                "carbs_g": round(total_carbs, 1),
                "fat_g": round(total_fat, 1),
            },
            "goal_calories": goal_cal,
            "remaining_calories": max(round(goal_cal - total_cal, 1), 0),
            "progress_pct": round(min(total_cal / goal_cal * 100, 100), 1),
        }
    }


@router.post("/goal", summary="设置每日卡路里目标")
def set_goal(body: CalorieGoalIn, db: Session = Depends(get_db)):
    row = db.query(CalorieGoal).filter(CalorieGoal.user_id == body.user_id).first()
    if row:
        row.daily_calories = body.daily_calories
        row.updated_at = datetime.now()
    else:
        row = CalorieGoal(
            id=uuid.uuid4(),
            user_id=body.user_id,
            daily_calories=body.daily_calories,
        )
        db.add(row)
    db.commit()
    return {
        "success": True,
        "data": {"user_id": body.user_id, "daily_calories": body.daily_calories, "message": "目标已更新"}
    }


@router.get("/bmr-calculator", summary="基础代谢率计算")
def bmr_calculator(
    gender: str = Query(..., pattern="^(male|female)$"),
    age: int = Query(..., ge=10, le=100),
    weight_kg: float = Query(..., gt=0),
    height_cm: float = Query(..., gt=0),
    activity_level: str = Query("moderate",
                                pattern="^(sedentary|light|moderate|active|very_active)$"),
):
    # Mifflin-St Jeor equation
    if gender == "male":
        bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age + 5
    else:
        bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age - 161

    multipliers = {
        "sedentary": 1.2, "light": 1.375, "moderate": 1.55,
        "active": 1.725, "very_active": 1.9,
    }
    tdee = bmr * multipliers[activity_level]

    return {
        "success": True,
        "data": {
            "bmr": round(bmr),
            "tdee": round(tdee),
            "activity_level": activity_level,
            "weight_loss_target": round(tdee - 500),
            "weight_gain_target": round(tdee + 300),
            "tcm_note": "中医注重因人制宜，热量仅为参考，体质调养更为关键。",
        }
    }
