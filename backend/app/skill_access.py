"""Skills access is derived from the authenticated account and paid entitlement."""
from dataclasses import dataclass
import time
from fastapi import Depends, HTTPException
from sqlalchemy.orm import Session
from .deps import current_user, get_session
from .locale_context import RequestLocale, request_locale
from .entitlements import tier_for_product
from .simple_models import Entitlement

@dataclass(frozen=True)
class SkillAccess:
    user_id: str
    premium: bool

    def require(self, requested_user: str | None, premium: bool = False):
        if requested_user is not None and requested_user != self.user_id:
            raise HTTPException(status_code=403, detail="不能代替其他用户调用此功能")
        if premium and not self.premium:
            raise HTTPException(status_code=403, detail="此能力需要有效会员权益")


def get_skill_access(
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
    locale: RequestLocale = Depends(request_locale),
) -> SkillAccess:
    # 未满 16 周岁不提供 AI 能力（与对话一致；监护人同意目前没有可靠核验手段，见 services/age_policy.py）
    from .services.age_policy import policy_for

    policy_for(session, user_id, locale.lang)
    entitlement = session.get(Entitlement, user_id)
    premium = bool(entitlement and entitlement.expires_at > time.time()
                   and tier_for_product(entitlement.product_id) != 'free')
    return SkillAccess(user_id, premium)
