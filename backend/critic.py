"""Gemma Health Edge — AI Response Critic & Hallucination Detector."""
import re
import logging
from typing import Dict, Tuple

logger = logging.getLogger("ghe.middleman.critic")

# ── Anatomical error patterns ─────────────────────────────────────────────────
ANATOMICAL_ERRORS: Dict[str, str] = {
    r"\bleft\s+(?:hand|foot|arm|leg)\s+is\s+(?:on|located)\s+(?:the\s+)?right\b": "Anatomical contradiction: left on right",
    r"\bright\s+(?:hand|foot|arm|leg)\s+is\s+(?:on|located)\s+(?:the\s+)?left\b": "Anatomical contradiction: right on left",
    r"\bheart\s+(?:is|is\s+located|located)\s+(?:on\s+)?(?:the\s+)?right\s+side\b": "Anatomical error: heart on right",
    r"\bliver\s+is\s+(?:on\s+)?(?:the\s+)?left\s+side\b": "Anatomical error: liver on left",
    r"\bstomach\s+is\s+(?:on\s+)?(?:the\s+)?right\s+side\b": "Anatomical error: stomach on right",
    r"\bspleen\s+is\s+(?:on\s+)?(?:the\s+)?right\s+side\b": "Anatomical error: spleen on right",
    r"\bgallbladder\s+is\s+(?:on\s+)?(?:the\s+)?left\s+side\b": "Anatomical error: gallbladder on left",
    r"\bappendix\s+is\s+(?:on\s+)?(?:the\s+)?left\s+side\b": "Anatomical error: appendix on left",
}

# ── Hallucination patterns ────────────────────────────────────────────────────
HALLUCINATION_PATTERNS: Dict[str, str] = {
    r"\b(?:cure|treatment|medicine)\s+(?:for|to)\s+(?:cancer|diabetes|alzheimer|hiv|aids)\s+(?:is|are)\s+(?:always|100%|guaranteed|completely)\s+(?:effective|curable)": "Medical hallucination: No universal cure",
    r"\b(?:all|every)\s+(?:cancer|disease|condition)\s+(?:can|could)\s+be\s+(?:cured|treated)\s+(?:by|with|using)\b": "Medical hallucination: Overgeneralized cure",
    r"\b(?:cures?|treats?)\s+(?:all\s+)?cancer\b": "Medical hallucination: Overgeneralized cure",
    r"\b(?:vaccines?|vaccination)\s+(?:cause|causes|causing)\s+(?:autism|cancer|infertility)": "Medical misinformation: Vaccine claims",
    r"\b(?:essential\s+oils?|herbs?|natural\s+remed(?:y|ies))\s+(?:cure|cures|treat|treats)\s+(?:cancer|diabetes|heart\s+disease|hiv|aids)\b": "Medical hallucination: Alternative cures",
    r"\b(?:miracle|magic|secret)\s+(?:cure|treatment|remedy)\b": "Medical hallucination: Miracle cure",
    r"\b(?:doctors?|medical\s+establishment)\s+(?:don't want|hide|suppress|conceal)\b": "Medical conspiracy claim",
    r"\b(?:disease|condition|symptom)\s+(?:is|are)\s+(?:always|never)\s+(?:caused\s+by|treated\s+by|prevented\s+by)\b": "Medical overgeneralization",
}

# ── Safety-critical patterns ──────────────────────────────────────────────────
SAFETY_CRITICAL: Dict[str, str] = {
    r"\bstop\s+(?:taking|using)\s+(?:your\s+)?(?:prescribed\s+)?(?:medication|medicine|prescription|insulin|vaccine)\b": "CRITICAL: Advising to stop prescribed medication",
    r"\b(?:don't|do\s+not)\s+(?:see|visit|consult)\s+(?:a\s+)?(?:your\s+)?(?:doctor|physician|medical|professional)\b": "CRITICAL: Discouraging medical consultation",
    r"\b(?:ignore|disregard)\s+(?:your\s+)?(?:doctor|physician)['']?s?\s+(?:advice|recommendation|prescription)\b": "CRITICAL: Advising to ignore doctor's orders",
    r"\bself[-\s]?diagnose\b": "WARNING: Self-diagnosis dangerous",
    r"\b(?:treat|treatment|medicat(?:e|ion))\s+(?:yourself|at\s+home)\s+(?:for|instead\s+of)\b": "WARNING: Self-treatment",
}

_ALL_PATTERNS = {**ANATOMICAL_ERRORS, **HALLUCINATION_PATTERNS, **SAFETY_CRITICAL}


class ResponseCritic:
    @staticmethod
    def analyze(response_text: str, query: str = "") -> Dict:
        issues, severity = [], "none"
        for pattern, msg in _ALL_PATTERNS.items():
            if re.search(pattern, response_text, re.IGNORECASE):
                issues.append(msg)
                severity = "critical" if "CRITICAL" in msg else "high"
        return {"issues": issues, "severity": severity}

    @staticmethod
    def should_block_response(critique: Dict) -> Tuple[bool, str]:
        if critique.get("severity") == "critical" and critique.get("issues"):
            return True, "critical_safety_issues"
        return False, ""


def critique_response(text: str, query: str = "") -> Dict:
    return ResponseCritic.analyze(text, query)