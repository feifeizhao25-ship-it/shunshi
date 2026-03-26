# 通知系统 API 路由
# 增强: FCM 推送 + APNs + 设备 token 管理 + 通知调度器
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, timedelta
import random
import logging
import threading
import time

logger = logging.getLogger(__name__)

# 尝试导入推送服务 SDK
try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    _FCM_AVAILABLE = True
except ImportError:
    _FCM_AVAILABLE = False
    logger.info("[Notifications] firebase-admin 未安装，FCM 推送将使用模拟模式")

router = APIRouter(prefix="/api/v1/notifications", tags=["通知"])

# ============ In-memory storage ============

notifications = {}
scheduled_notifications = {}
device_tokens = {}  # user_id -> list of device tokens

# ============ Notification Templates ============

SOLAR_TERM_NOTIFICATIONS = [
    {"title": "今日{term}", "body": "现在是{term}时节，{suggestion}"},
    {"title": "养生提醒", "body": "今日宜{suggestion}"},
    {"title": "节气养生", "body": "{term}到了，这些养生要点请注意：{suggestion}"}
]

FOLLOWUP_NOTIFICATIONS = [
    {"title": "任务提醒", "body": "你有一个养生任务待完成：{task}"},
    {"title": "健康提醒", "body": "别忘了今天的健康任务：{task}"},
    {"title": "养生打卡", "body": "今日养生任务：{task}"}
]

# ============ Models ============

class Notification(BaseModel):
    id: str
    type: str
    title: str
    body: str
    data: Optional[dict] = None
    is_read: bool = False
    scheduled_at: Optional[str] = None
    sent_at: Optional[str] = None

class ScheduleNotificationRequest(BaseModel):
    type: str  # solar_term / followup / custom
    title: str
    body: str
    data: Optional[dict] = None
    scheduled_at: str

class DeviceTokenRequest(BaseModel):
    token: str
    platform: str = "fcm"  # fcm / apns

class BulkNotificationRequest(BaseModel):
    user_ids: List[str]
    title: str
    body: str
    data: Optional[dict] = None

# ============ FCM Push ============

def send_push_notification(
    device_token: str,
    title: str,
    body: str,
    data: Optional[dict] = None,
    platform: str = "fcm",
) -> dict:
    """
    发送推送通知
    
    FCM: 使用 firebase-admin SDK
    APNs: 通过 FCM 统一推送 (iOS 设备通过 FCM token 推送)
    
    降级: 当 SDK 不可用时，记录日志
    """
    message_data = {
        "title": title,
        "body": body,
        **(data or {}),
    }
    
    if _FCM_AVAILABLE and firebase_admin._apps:
        try:
            # 构建 FCM 消息
            fcm_message = messaging.Message(
                token=device_token,
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data={k: str(v) for k, v in message_data.items()},
                android=messaging.AndroidConfig(
                    priority="high",
                    notification=messaging.AndroidNotification(
                        sound="default",
                        channel_id="shunshi_health",
                    ),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound="default",
                            badge=1,
                        ),
                    ),
                    headers={
                        "apns-priority": "10",
                    },
                ),
            )
            
            response = messaging.send(fcm_message)
            logger.info(f"[FCM] 推送成功: token={device_token[:20]}..., response={response}")
            return {
                "success": True,
                "message_id": response,
                "provider": "fcm",
            }
        except Exception as e:
            logger.warning(f"[FCM] 推送失败，降级到日志: {e}")
            return {
                "success": False,
                "error": str(e),
                "provider": "fcm",
            }
    else:
        # 模拟模式
        logger.info(f"[Push-MOCK] 推送通知: token={device_token[:20]}..., title={title}, body={body}")
        return {
            "success": True,
            "message_id": f"mock_{random.randint(100000, 999999)}",
            "provider": "mock",
        }

def send_push_to_user(user_id: str, title: str, body: str, data: Optional[dict] = None) -> dict:
    """向用户所有设备发送推送"""
    tokens = device_tokens.get(user_id, [])
    
    if not tokens:
        logger.info(f"[Push] 用户 {user_id} 没有注册设备 token")
        return {"success": True, "sent_count": 0, "message": "无已注册设备"}
    
    results = []
    for token_info in tokens:
        result = send_push_notification(
            device_token=token_info["token"],
            title=title,
            body=body,
            data=data,
            platform=token_info.get("platform", "fcm"),
        )
        results.append(result)
    
    success_count = sum(1 for r in results if r.get("success"))
    
    return {
        "success": success_count > 0,
        "sent_count": success_count,
        "total_devices": len(tokens),
        "results": results,
    }

def initialize_fcm(credentials_path: Optional[str] = None):
    """
    初始化 Firebase Admin SDK
    
    credentials_path: 服务账号 JSON 文件路径
    """
    if not _FCM_AVAILABLE:
        logger.info("[FCM] firebase-admin 未安装，使用模拟模式")
        return False
    
    if firebase_admin._apps:
        logger.info("[FCM] 已初始化")
        return True
    
    try:
        if credentials_path:
            cred = credentials.Certificate(credentials_path)
            firebase_admin.initialize_app(cred)
        else:
            # 使用默认凭据（Google Cloud 环境）
            firebase_admin.initialize_app()
        logger.info("[FCM] Firebase Admin SDK 初始化成功")
        return True
    except Exception as e:
        logger.warning(f"[FCM] 初始化失败，使用模拟模式: {e}")
        return False

# ============ 通知调度器 ============

class NotificationScheduler:
    """通知调度器 - 定时检查并发送到期通知"""
    
    def __init__(self, check_interval: int = 60):
        self._running = False
        self._thread: Optional[threading.Thread] = None
        self._check_interval = check_interval
    
    def start(self):
        """启动调度器"""
        if self._running:
            return
        self._running = True
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()
        logger.info(f"[Scheduler] 通知调度器已启动，检查间隔: {self._check_interval}s")
    
    def stop(self):
        """停止调度器"""
        self._running = False
        if self._thread:
            self._thread.join(timeout=5)
        logger.info("[Scheduler] 通知调度器已停止")
    
    def _run(self):
        """调度器主循环"""
        while self._running:
            try:
                self._check_and_send()
            except Exception as e:
                logger.error(f"[Scheduler] 调度错误: {e}")
            time.sleep(self._check_interval)
    
    def _check_and_send(self):
        """检查并发送到期通知"""
        now = datetime.now()
        
        for user_id, scheduled_list in list(scheduled_notifications.items()):
            for scheduled in scheduled_list:
                if scheduled.get("status") != "pending":
                    continue
                
                try:
                    scheduled_at = datetime.fromisoformat(scheduled["scheduled_at"])
                except (ValueError, TypeError):
                    continue
                
                if now >= scheduled_at:
                    # 发送通知
                    send_push_to_user(
                        user_id=user_id,
                        title=scheduled["title"],
                        body=scheduled["body"],
                        data=scheduled.get("data"),
                    )
                    
                    # 保存到已发送通知
                    notif_id = scheduled["id"]
                    notification = {
                        "id": notif_id,
                        "type": scheduled["type"],
                        "title": scheduled["title"],
                        "body": scheduled["body"],
                        "data": scheduled.get("data", {}),
                        "is_read": False,
                        "sent_at": now.isoformat(),
                    }
                    
                    if user_id not in notifications:
                        notifications[user_id] = []
                    notifications[user_id].append(notification)
                    
                    # 标记已发送
                    scheduled["status"] = "sent"
                    scheduled["sent_at"] = now.isoformat()
                    
                    logger.info(f"[Scheduler] 定时通知已发送: {notif_id} to {user_id}")


# 全局调度器实例
notification_scheduler = NotificationScheduler(check_interval=60)

# ============ Helper Functions ============

def generate_notification_id():
    return f"notif_{datetime.now().strftime('%Y%m%d%H%M%S')}_{random.randint(1000, 9999)}"

def get_user_notifications(user_id: str, unread_only: bool = False):
    """获取用户通知"""
    if user_id not in notifications:
        notifications[user_id] = []
    
    notifs = notifications[user_id]
    
    if unread_only:
        notifs = [n for n in notifs if not n.get("is_read", False)]
    
    return notifs

# ============ API Endpoints (原有) ============

@router.get("", response_model=dict)
async def get_notifications(
    user_id: str = Query("user-001"),
    unread_only: bool = Query(False),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100)
):
    """获取通知列表"""
    notifs = get_user_notifications(user_id, unread_only)
    
    notifs = sorted(notifs, key=lambda x: x.get("sent_at", ""), reverse=True)
    
    start = (page - 1) * limit
    end = start + limit
    items = notifs[start:end]
    
    unread_count = len([n for n in notifications.get(user_id, []) if not n.get("is_read", False)])
    
    return {
        "success": True,
        "data": {
            "items": items,
            "total": len(notifs),
            "unread_count": unread_count,
            "page": page,
            "limit": limit
        }
    }

@router.get("/unread-count", response_model=dict)
async def get_unread_count(user_id: str = Query("user-001")):
    """获取未读数量"""
    notifs = get_user_notifications(user_id)
    unread_count = len([n for n in notifs if not n.get("is_read", False)])
    
    return {
        "success": True,
        "data": {"unread_count": unread_count}
    }

@router.post("", response_model=dict)
async def send_notification(
    type: str = Query(...),
    title: str = Query(...),
    body: str = Query(...),
    user_id: str = Query("user-001"),
    data: Optional[dict] = None,
    push: bool = Query(True),
):
    """发送通知（可选推送到设备）"""
    notif_id = generate_notification_id()
    now = datetime.now().isoformat()
    
    notification = {
        "id": notif_id,
        "type": type,
        "title": title,
        "body": body,
        "data": data or {},
        "is_read": False,
        "sent_at": now
    }
    
    if user_id not in notifications:
        notifications[user_id] = []
    
    notifications[user_id].append(notification)
    
    # 推送到设备
    push_result = None
    if push:
        push_result = send_push_to_user(user_id, title, body, data)
    
    return {
        "success": True,
        "data": {
            **notification,
            "push_result": push_result,
        }
    }

@router.post("/read-all", response_model=dict)
async def mark_all_read(user_id: str = Query("user-001")):
    """标记全部已读"""
    if user_id in notifications:
        for notif in notifications[user_id]:
            notif["is_read"] = True
    
    return {"success": True, "message": "已全部标记为已读"}

@router.post("/{notification_id}/read", response_model=dict)
async def mark_read(
    notification_id: str,
    user_id: str = Query("user-001")
):
    """标记已读"""
    notifs = notifications.get(user_id, [])
    
    for notif in notifs:
        if notif["id"] == notification_id:
            notif["is_read"] = True
            return {"success": True, "data": notif}
    
    raise HTTPException(status_code=404, detail="通知不存在")

@router.delete("/{notification_id}", response_model=dict)
async def delete_notification(
    notification_id: str,
    user_id: str = Query("user-001")
):
    """删除通知"""
    if user_id in notifications:
        notifications[user_id] = [n for n in notifications[user_id] if n["id"] != notification_id]
    
    return {"success": True, "message": "删除成功"}

@router.post("/schedule", response_model=dict)
async def schedule_notification(
    request: ScheduleNotificationRequest,
    user_id: str = Query("user-001")
):
    """定时发送通知"""
    notif_id = generate_notification_id()
    
    scheduled = {
        "id": notif_id,
        "user_id": user_id,
        "type": request.type,
        "title": request.title,
        "body": request.body,
        "data": request.data or {},
        "scheduled_at": request.scheduled_at,
        "status": "pending"
    }
    
    if user_id not in scheduled_notifications:
        scheduled_notifications[user_id] = []
    
    scheduled_notifications[user_id].append(scheduled)
    
    return {
        "success": True,
        "data": scheduled
    }

@router.get("/schedule", response_model=dict)
async def get_scheduled_notifications(
    user_id: str = Query("user-001")
):
    """获取定时通知列表"""
    scheduled = scheduled_notifications.get(user_id, [])
    
    return {
        "success": True,
        "data": scheduled
    }

@router.delete("/schedule/{notification_id}", response_model=dict)
async def cancel_scheduled(
    notification_id: str,
    user_id: str = Query("user-001")
):
    """取消定时通知"""
    if user_id in scheduled_notifications:
        scheduled_notifications[user_id] = [
            n for n in scheduled_notifications[user_id] 
            if n["id"] != notification_id
        ]
    
    return {"success": True, "message": "取消成功"}

# ============ 通知模板 API ============

@router.get("/templates/solar-term", response_model=dict)
async def get_solar_term_templates():
    """获取节气通知模板"""
    return {
        "success": True,
        "data": SOLAR_TERM_NOTIFICATIONS
    }

@router.get("/templates/followup", response_model=dict)
async def get_followup_templates():
    """获取 Follow-up 通知模板"""
    return {
        "success": True,
        "data": FOLLOWUP_NOTIFICATIONS
    }

# ============ 通知设置 API ============

@router.get("/settings", response_model=dict)
async def get_notification_settings(user_id: str = Query("user-001")):
    """获取通知设置"""
    settings = {
        "enabled": True,
        "solar_term": True,
        "followup": True,
        "marketing": False,
        "quiet_hours": {
            "enabled": False,
            "start": "22:00",
            "end": "08:00"
        }
    }
    
    return {"success": True, "data": settings}

@router.post("/settings", response_model=dict)
async def update_notification_settings(
    user_id: str = Query("user-001"),
    enabled: bool = Query(True),
    solar_term: bool = Query(True),
    followup: bool = Query(True),
    marketing: bool = Query(False),
    quiet_hours_enabled: bool = Query(False),
    quiet_hours_start: str = Query("22:00"),
    quiet_hours_end: str = Query("08:00")
):
    """更新通知设置"""
    settings = {
        "enabled": enabled,
        "solar_term": solar_term,
        "followup": followup,
        "marketing": marketing,
        "quiet_hours": {
            "enabled": quiet_hours_enabled,
            "start": quiet_hours_start,
            "end": quiet_hours_end
        }
    }
    
    return {
        "success": True,
        "data": settings,
        "message": "设置已更新"
    }

# ============ 设备 Token 管理 ============

@router.post("/devices/register", response_model=dict)
async def register_device(
    request: DeviceTokenRequest,
    user_id: str = Query("user-001"),
):
    """注册设备推送 token"""
    if user_id not in device_tokens:
        device_tokens[user_id] = []
    
    # 检查是否已注册
    existing = [t for t in device_tokens[user_id] if t["token"] == request.token]
    if existing:
        existing[0]["platform"] = request.platform
        existing[0]["updated_at"] = datetime.now().isoformat()
        return {"success": True, "message": "设备已更新"}
    
    device_tokens[user_id].append({
        "token": request.token,
        "platform": request.platform,
        "registered_at": datetime.now().isoformat(),
    })
    
    logger.info(f"[Device] 注册设备: user={user_id}, platform={request.platform}, token={request.token[:20]}...")
    
    return {"success": True, "message": "设备注册成功", "device_count": len(device_tokens[user_id])}

@router.post("/devices/unregister", response_model=dict)
async def unregister_device(
    request: DeviceTokenRequest,
    user_id: str = Query("user-001"),
):
    """注销设备推送 token"""
    if user_id in device_tokens:
        before = len(device_tokens[user_id])
        device_tokens[user_id] = [
            t for t in device_tokens[user_id]
            if t["token"] != request.token
        ]
        removed = before - len(device_tokens[user_id])
        
        if removed > 0:
            logger.info(f"[Device] 注销设备: user={user_id}, removed={removed}")
            return {"success": True, "message": f"已注销 {removed} 个设备"}
    
    return {"success": True, "message": "设备未找到"}

@router.get("/devices", response_model=dict)
async def list_devices(user_id: str = Query("user-001")):
    """获取用户已注册设备列表"""
    tokens = device_tokens.get(user_id, [])
    
    # 脱敏
    safe_tokens = [
        {
            "platform": t["platform"],
            "token_preview": f"{t['token'][:20]}...",
            "registered_at": t.get("registered_at"),
        }
        for t in tokens
    ]
    
    return {
        "success": True,
        "data": {
            "devices": safe_tokens,
            "total": len(tokens),
        }
    }

# ============ 批量推送 ============

@router.post("/push/batch", response_model=dict)
async def push_batch(request: BulkNotificationRequest):
    """批量推送通知"""
    results = {}
    
    for user_id in request.user_ids:
        result = send_push_to_user(
            user_id=user_id,
            title=request.title,
            body=request.body,
            data=request.data,
        )
        results[user_id] = result
    
    success_count = sum(1 for r in results.values() if r.get("success"))
    
    return {
        "success": True,
        "data": {
            "total": len(request.user_ids),
            "sent": success_count,
            "results": results,
        }
    }

# ============ 调度器控制 ============

@router.post("/scheduler/start", response_model=dict)
async def start_scheduler():
    """启动通知调度器"""
    notification_scheduler.start()
    return {"success": True, "message": "调度器已启动"}

@router.post("/followup-due", response_model=dict)
async def push_followup_due(user_id: str = Query(..., description="用户ID")):
    """推送到期 Follow-up 提醒通知
    
    检查用户到期的 Follow-up 并发送推送提醒。
    可由 cron 或调度器每15分钟调用。
    """
    try:
        from app.services.followup_scheduler import followup_scheduler
    except ImportError:
        return {"success": False, "error": "followup scheduler not available"}
    
    # 检查到期任务
    due_followups = followup_scheduler.check_due_followups()
    user_due = [f for f in due_followups if f.get("user_id") == user_id]
    
    if not user_due:
        return {"success": True, "data": {"triggered": 0, "message": "no due followups"}}
    
    # 为每个到期任务创建通知
    triggered = 0
    for fu in user_due:
        template = FOLLOWUP_NOTIFICATIONS[0]
        title = template["title"]
        body = template["body"].format(task=fu.get("title", fu.get("type", "health check")))
        
        # 保存通知
        notif_id = generate_notification_id()
        now = datetime.now().isoformat()
        notification = {
            "id": notif_id,
            "type": "followup",
            "title": title,
            "body": body,
            "data": {"followup_id": fu.get("id", ""), "source": "followup_due"},
            "is_read": False,
            "sent_at": now,
        }
        
        if user_id not in notifications:
            notifications[user_id] = []
        notifications[user_id].append(notification)
        
        # 推送
        send_push_to_user(user_id, title, body, notification.get("data"))
        triggered += 1
    
    return {
        "success": True,
        "data": {
            "triggered": triggered,
            "total_due": len(user_due),
            "message": f"已发送 {triggered} 条 Follow-up 提醒",
        }
    }


@router.post("/scheduler/stop", response_model=dict)
async def stop_scheduler():
    """停止通知调度器"""
    notification_scheduler.stop()
    return {"success": True, "message": "调度器已停止"}

@router.get("/scheduler/status", response_model=dict)
async def scheduler_status():
    """获取调度器状态"""
    return {
        "success": True,
        "data": {
            "running": notification_scheduler._running,
            "check_interval": notification_scheduler._check_interval,
            "fcm_available": _FCM_AVAILABLE,
            "registered_devices": sum(len(v) for v in device_tokens.values()),
        }
    }
