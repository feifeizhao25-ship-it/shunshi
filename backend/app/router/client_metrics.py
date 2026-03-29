"""
Client-side Metrics Batch Ingest Endpoint
Receives batched analytics events from SEASONS and ShunShi mobile apps.
"""

import logging
from datetime import datetime
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Body, Request
from pydantic import BaseModel, Field

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/metrics", tags=["client-metrics"])


class ClientEvent(BaseModel):
    event: str
    user_id: Optional[str] = None
    properties: Dict[str, Any] = Field(default_factory=dict)
    timestamp: Optional[str] = None
    platform: Optional[str] = None


class BatchEventsRequest(BaseModel):
    events: List[ClientEvent]


@router.post("/batch")
async def ingest_batch_events(
    payload: BatchEventsRequest,
    request: Request,
):
    """
    Ingest a batch of client-side analytics events.
    Used by both SEASONS and ShunShi mobile apps.
    """
    received_at = datetime.utcnow().isoformat()
    count = len(payload.events)

    if count == 0:
        return {"status": "ok", "received": 0}

    # Log events (in production, persist to analytics DB / data warehouse)
    for event in payload.events:
        logger.info(
            "[ClientMetrics] event=%s user=%s platform=%s props=%s",
            event.event,
            event.user_id or "anonymous",
            event.platform or "unknown",
            event.properties,
        )

    # In production: async insert to ClickHouse / BigQuery / Mixpanel etc.
    # For now, we accept and log silently to avoid blocking the client.

    return {
        "status": "ok",
        "received": count,
        "received_at": received_at,
    }


@router.get("/health")
async def metrics_health():
    """Metrics ingest health check."""
    return {"status": "ok"}
