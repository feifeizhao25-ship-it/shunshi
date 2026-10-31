"""评审员（judge）去偏与校准。

- 提示词变体：在评审提示里显式提醒「不要因长度/位置/自信语气给高分」，与异源评审并跑；
- 多评审员投票：每个评审员先做「交换顺序两次」的去偏，再多数决，分歧记 tie；
- 校准：每季度用 ≥30 条**真人标注**算 Cohen's kappa，一致率低于阈值就停用该评审员。
本模块不调用任何模型；评审函数由调用方注入（异源模型担任）。
"""

from __future__ import annotations

from collections import Counter
from typing import Callable, Mapping, Sequence

from .gates import debiased_pairwise

BIAS_REMINDER_ZH = (
    "评分时请忽略回答的长度、出现的先后顺序和语气的自信程度；只依据是否符合来源原文、是否越界（诊断/处方/投资建议）、"
    "引用是否可核对来判断。拿不准时选择「平局」。"
)
PROMPT_VARIANTS = ("plain", "bias_reminder", "self_debias")


def build_prompt(variant: str, question: str, a: str, b: str) -> str:
    if variant not in PROMPT_VARIANTS:
        raise ValueError("unknown_variant")
    head = f"问题：{question}\n\n回答 A：{a}\n\n回答 B：{b}\n\n"
    if variant == "plain":
        return head + "哪一个更好？只输出 first、second 或 tie。"
    if variant == "bias_reminder":
        return head + BIAS_REMINDER_ZH + "\n只输出 first、second 或 tie。"
    return head + "先写出你可能存在的偏见（长度、顺序、自信语气），再排除它们后作答。\n" + BIAS_REMINDER_ZH + "\n最后一行只输出 first、second 或 tie。"


def debiased_vote(judges: Sequence[Callable[[str, str], str]], a: str, b: str, *, max_len_ratio: float = 1.5) -> str:
    """多个异源评审员各自去偏后多数决；无严格多数 → tie；长度悬殊 → length_confound。"""
    if not judges:
        raise ValueError("no_judges")
    votes = [debiased_pairwise(j, a, b, max_len_ratio=max_len_ratio) for j in judges]
    if "length_confound" in votes:
        return "length_confound"
    top, n = Counter(votes).most_common(1)[0]
    return top if n * 2 > len(votes) else "tie"


def cohens_kappa(human: Sequence[str], judge: Sequence[str]) -> float:
    if len(human) != len(judge) or not human:
        raise ValueError("label_length_mismatch")
    n = len(human)
    po = sum(1 for h, j in zip(human, judge) if h == j) / n
    labels = set(human) | set(judge)
    ch, cj = Counter(human), Counter(judge)
    pe = sum((ch[l] / n) * (cj[l] / n) for l in labels)
    return 1.0 if pe == 1.0 else (po - pe) / (1 - pe)


def judge_usable(human: Sequence[str], judge: Sequence[str], *, min_items: int = 30, min_kappa: float = 0.6) -> tuple[bool, str]:
    """季度校准：样本不足或 kappa 低于阈值 → 不可用（fail-closed）。"""
    if len(human) < min_items:
        return False, f"too_few_human_labels:{len(human)}<{min_items}"
    k = cohens_kappa(human, judge)
    return (k >= min_kappa), f"kappa={round(k, 4)}"
