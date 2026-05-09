"""SQLAlchemy models - all registered with Base."""
from __future__ import annotations

from app.db.database import Base
from app.models.user import User, UserAuth, FamilyMember, UserDevice
from app.models.solar_term import SolarTerm, SolarTermContent
from app.models.constitution import Constitution, ConstitutionQuestion, ConstitutionResult
from app.models.recipe import Recipe
from app.models.tea import Tea, TeaFavorite
from app.models.acupoint import Acupoint
from app.models.exercise import Exercise, ExerciseFavorite, ExerciseLog
from app.models.chat import ChatMessage, ChatConversation, ChatMemory
from app.models.journal import JournalEntry, JournalPhoto
from app.models.article import Article
from app.models.audio import AudioTrack, AudioPlayHistory
from app.models.membership import MembershipPlan, UserMembership, MembershipBenefitUsage
from app.models.reminder import Reminder, ReminderLog
from app.models.content import ContentItem, ContentMedia, ContentTag, ContentTagRelation

__all__ = [
    "Base", "User", "UserAuth", "FamilyMember", "UserDevice",
    "SolarTerm", "SolarTermContent",
    "Constitution", "ConstitutionQuestion", "ConstitutionResult",
    "Recipe", "Tea", "TeaFavorite", "Acupoint",
    "Exercise", "ExerciseFavorite", "ExerciseLog",
    "ChatMessage", "ChatConversation", "ChatMemory",
    "JournalEntry", "JournalPhoto",
    "Article", "AudioTrack", "AudioPlayHistory",
    "MembershipPlan", "UserMembership", "MembershipBenefitUsage",
    "Reminder", "ReminderLog",
    "ContentItem", "ContentMedia", "ContentTag", "ContentTagRelation",
]
