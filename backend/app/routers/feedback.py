"""反馈模块：契约以 Flutter 客户端实际调用为准（core/feedback.dart）。

- POST /api/v1/feedback         body {"content", "contact"?, "screenshots"?} → {"id", "saved": true}
- POST /api/v1/feedback/rating  body {"rating": 1-5, "comment"?}            → {"id", "saved": true}
"""

import json

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from ..deps import current_user, get_session
from ..simple_models import Feedback

router = APIRouter(prefix="/api/v1/feedback", tags=["feedback"])


class FeedbackBody(BaseModel):
    content: str = Field(min_length=1, max_length=10000)
    contact: str | None = Field(default=None, max_length=128)
    screenshots: list[str] | None = Field(default=None, max_length=9)


class RatingBody(BaseModel):
    rating: int = Field(ge=1, le=5)
    comment: str | None = Field(default=None, max_length=5000)


def _save(session: Session, user_id: str, kind: str, payload: dict) -> dict:
    item = Feedback(
        user_id=user_id,
        kind=kind,
        payload=json.dumps(payload, ensure_ascii=False),
    )
    session.add(item)
    session.flush()
    return {"id": item.id, "saved": True}


@router.post("")
def submit_feedback(
    body: FeedbackBody,
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    return _save(session, user_id, "feedback", body.model_dump(exclude_none=True))


@router.post("/rating")
def submit_rating(
    body: RatingBody,
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    return _save(session, user_id, "rating", body.model_dump(exclude_none=True))
