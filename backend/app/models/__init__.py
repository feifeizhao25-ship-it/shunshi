"""SQLAlchemy models - all registered with Base."""
from app.db.database import Base
from app.models.user import User, UserAuth, FamilyMember, UserDevice
from app.models.solar_term import SolarTerm, SolarTermInstance
from app.models.constitution import ConstitutionType, ConstitutionQuestion, ConstitutionTestRecord
from app.models.recipe import Recipe
from app.models.tea import TeaRecipe
from app.models.acupoint import Acupoint
from app.models.exercise import ExerciseTutorial
from app.models.chat import ChatSession, ChatMessage
from app.models.journal import WellnessJournal, WellnessReport
from app.models.article import Article
from app.models.audio import AudioContent
from app.models.user_favorite import UserFavorite
from app.models.membership import MembershipOrder, PointRecord, ReferralCode
from app.models.reminder import ReminderTemplate, UserReminder

__all__ = [
    "Base", "User", "UserAuth", "FamilyMember", "UserDevice",
    "SolarTerm", "SolarTermInstance",
    "ConstitutionType", "ConstitutionQuestion", "ConstitutionTestRecord",
    "Recipe", "TeaRecipe", "Acupoint", "ExerciseTutorial",
    "ChatSession", "ChatMessage",
    "WellnessJournal", "WellnessReport",
    "Article", "AudioContent", "UserFavorite",
    "MembershipOrder", "PointRecord", "ReferralCode",
    "ReminderTemplate", "UserReminder",
]
