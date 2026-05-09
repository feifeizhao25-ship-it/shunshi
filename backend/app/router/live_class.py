"""
顺时 — 直播课程 API (shunshi-live-class)
养生直播课、录播课、课程预约 (PostgreSQL backed)
"""
import uuid
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.wellness_tracking import LiveClassBooking

router = APIRouter(prefix="/api/v1/live-class", tags=["live-class"])

_CLASSES = {
    "class_001": {
        "class_id": "class_001",
        "title": "二十四节气养生功法精讲",
        "instructor": "李明华主任中医师",
        "class_type": "live",
        "category": "exercise",
        "duration_minutes": 60,
        "scheduled_at": "2024-03-20T19:00:00",
        "max_students": 500,
        "current_students": 128,
        "price": 0,
        "description": "跟随节气调整功法练习，春季疏肝、夏季养心……",
        "tags": ["节气", "功法", "免费"],
    },
    "class_002": {
        "class_id": "class_002",
        "title": "体质辨识与日常调养",
        "instructor": "王秀芳副主任中医师",
        "class_type": "live",
        "category": "constitution",
        "duration_minutes": 90,
        "scheduled_at": "2024-03-22T20:00:00",
        "max_students": 300,
        "current_students": 89,
        "price": 19.9,
        "description": "九种体质详细解析，帮助你精准定位自身体质并制定调养方案。",
        "tags": ["体质", "调养"],
    },
    "class_003": {
        "class_id": "class_003",
        "title": "食疗方案实操课",
        "instructor": "张建国中医师",
        "class_type": "recorded",
        "category": "food",
        "duration_minutes": 45,
        "scheduled_at": None,
        "max_students": None,
        "current_students": 2341,
        "price": 9.9,
        "description": "手把手教你制作日常养生食疗方，简单易做效果好。",
        "tags": ["食疗", "录播", "实操"],
    },
    "class_004": {
        "class_id": "class_004",
        "title": "八段锦完整教学（入门版）",
        "instructor": "顺时养生团队",
        "class_type": "recorded",
        "category": "exercise",
        "duration_minutes": 30,
        "scheduled_at": None,
        "max_students": None,
        "current_students": 5678,
        "price": 0,
        "description": "八段锦八节完整教学，适合零基础学员。",
        "tags": ["八段锦", "录播", "免费", "入门"],
    },
}

_CATEGORIES = [
    {"id": "exercise", "name": "功法运动"},
    {"id": "constitution", "name": "体质调理"},
    {"id": "food", "name": "食疗药膳"},
    {"id": "meditation", "name": "冥想放松"},
    {"id": "knowledge", "name": "中医知识"},
]


class BookIn(BaseModel):
    user_id: str


@router.get("/list", summary="课程列表")
def list_classes(
    class_type: Optional[str] = Query(None, enum=["live", "recorded"]),
    category: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=50),
):
    classes = list(_CLASSES.values())
    if class_type:
        classes = [c for c in classes if c["class_type"] == class_type]
    if category:
        classes = [c for c in classes if c["category"] == category]
    total = len(classes)
    start = (page - 1) * page_size
    return {
        "success": True,
        "data": {
            "classes": classes[start:start + page_size],
            "total": total,
            "page": page,
        }
    }


@router.get("/{class_id}", summary="课程详情")
def get_class(class_id: str):
    if class_id not in _CLASSES:
        raise HTTPException(status_code=404, detail="课程不存在")
    return {"success": True, "data": _CLASSES[class_id]}


@router.post("/{class_id}/book", summary="预约课程")
def book_class(class_id: str, body: BookIn, db: Session = Depends(get_db)):
    if class_id not in _CLASSES:
        raise HTTPException(status_code=404, detail="课程不存在")
    # Check for duplicate booking
    existing = db.query(LiveClassBooking).filter(
        LiveClassBooking.user_id == body.user_id,
        LiveClassBooking.class_id == class_id,
        LiveClassBooking.status == "booked",
    ).first()
    if existing:
        return {
            "success": True,
            "data": {
                "booking_id": str(existing.id),
                "class_id": class_id,
                "status": "already_booked",
                "message": "您已预约该课程",
            }
        }
    booking = LiveClassBooking(
        id=uuid.uuid4(),
        user_id=body.user_id,
        class_id=class_id,
        status="booked",
        booked_at=datetime.now(),
    )
    db.add(booking)
    db.commit()
    db.refresh(booking)
    cls = _CLASSES[class_id]
    return {
        "success": True,
        "data": {
            "booking_id": str(booking.id),
            "class_id": class_id,
            "class_title": cls["title"],
            "class_type": cls["class_type"],
            "scheduled_at": cls.get("scheduled_at"),
            "status": "booked",
            "booked_at": booking.booked_at.isoformat(),
        }
    }


@router.get("/bookings/{user_id}", summary="我的预约")
def my_bookings(user_id: str, db: Session = Depends(get_db)):
    rows = db.query(LiveClassBooking).filter(
        LiveClassBooking.user_id == user_id,
    ).order_by(LiveClassBooking.booked_at.desc()).all()
    return {
        "success": True,
        "data": {
            "bookings": [
                {
                    "booking_id": str(r.id),
                    "class_id": r.class_id,
                    "class": _CLASSES.get(r.class_id, {"class_id": r.class_id}),
                    "status": r.status,
                    "booked_at": r.booked_at.isoformat(),
                }
                for r in rows
            ],
            "total": len(rows),
        }
    }


@router.get("/categories/list", summary="课程分类")
def list_categories():
    return {"success": True, "data": {"categories": _CATEGORIES}}


@router.get("/upcoming/schedule", summary="近期直播预告")
def upcoming_schedule():
    upcoming = [c for c in _CLASSES.values() if c["class_type"] == "live" and c.get("scheduled_at")]
    upcoming.sort(key=lambda x: x["scheduled_at"])
    return {
        "success": True,
        "data": {"upcoming": upcoming, "total": len(upcoming)}
    }
