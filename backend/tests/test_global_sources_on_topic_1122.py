"""SEASONS (international) chat sources must be about the question (11-21 UI test: a Ramadan meal question was
answered with the CDC adult-sleep note as its source)."""
import os

import pytest

from app.rag.evidence import verified_global_context
from app.rag.knowledge_base import load_knowledge_bases


@pytest.fixture(scope="module", autouse=True)
def _runtime_kb():
    """The user-facing runtime corpus (no legacy eval documents), which is what the 11-21 UI run used."""
    load_knowledge_bases(force=True, include_legacy=False)
    yield
    load_knowledge_bases(force=True, include_legacy=os.environ.get("SHUNSHI_KB_LEGACY_EVAL") == "1")


def _titles(q):
    return [d["title"] for d in verified_global_context(q)[2]]


@pytest.mark.parametrize(
    "question",
    [
        "I am fasting for Ramadan next year — how should I plan meals around suhoor and iftar?",
        "I keep waking up at 3am. What can I try tonight?",
        "I am 67 and my knees hurt in winter. Any gentle routine?",
        "Should I take ashwagandha? How much?",
    ],
)
def test_off_topic_questions_get_no_source(question):
    assert _titles(question) == []


@pytest.mark.parametrize(
    "question, title",
    [
        ("how can I sleep better", "Adult sleep duration and sleep habits"),
        ("how much exercise should I do a week", "Weekly activity for adults"),
        ("how much salt is too much", "Fruit, vegetables, salt and sugar"),
        ("what should I eat this winter", "Fruit, vegetables, salt and sugar"),
        ("I feel low in winter", "Low mood in darker months"),
    ],
)
def test_on_topic_questions_keep_their_source(question, title):
    assert _titles(question)[:1] == [title]


def test_passing_body_word_alone_does_not_attach_a_second_source():
    # "sleep" appears in the seasonal-mood note's body ("keep regular sleep and waking times") but not its headings.
    assert _titles("how can I sleep better") == ["Adult sleep duration and sleep habits"]
