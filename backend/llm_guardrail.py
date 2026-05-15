"""Gemma Health Edge — LLM-Based Safety Guardrail.

Secondary validation layer using the local Gemma 4 model to cross-check
AI responses for medical safety issues, with a circuit breaker to
prevent cascading failures when the guardrail model is unavailable.
"""
import json
import logging
import time
from typing import Dict, Tuple

import httpx

from config import settings, get_http_client

logger = logging.getLogger("ghe.middleman.guardrail")

# ── Circuit Breaker Constants ─────────────────────────────────────────────────
_TRIP_THRESHOLD = 3        # failures before opening
_RESET_WINDOW_S = 120      # seconds before attempting half-open
_PROBE_TIMEOUT  = 5.0      # timeout for half-open probe request

_STATE_CLOSED    = "closed"
_STATE_OPEN      = "open"
_STATE_HALF_OPEN = "half_open"


class _CircuitBreaker:
    """Simple three-state circuit breaker to protect the guardrail LLM call."""

    def __init__(self) -> None:
        self.state = _STATE_CLOSED
        self._failures = 0
        self._trip_time = 0.0
        self._success_count = 0

    def record_success(self) -> None:
        if self.state == _STATE_HALF_OPEN:
            self._success_count += 1
            if self._success_count >= 2:
                self.state = _STATE_CLOSED
                self._failures = 0
                self._success_count = 0
                logger.info("[GuardrailCB] Circuit CLOSED after successful probe.")
        elif self.state == _STATE_CLOSED:
            self._failures = 0

    def record_failure(self) -> None:
        self._failures += 1
        self._success_count = 0
        if self.state == _STATE_CLOSED and self._failures >= _TRIP_THRESHOLD:
            self.state = _STATE_OPEN
            self._trip_time = time.monotonic()
            logger.error("[GuardrailCB] Circuit OPENED after %d failures.", self._failures)
        elif self.state == _STATE_HALF_OPEN:
            self.state = _STATE_OPEN
            self._trip_time = time.monotonic()
            logger.warning("[GuardrailCB] Half-open probe FAILED — circuit re-opened.")

    def allow_request(self) -> bool:
        if self.state == _STATE_CLOSED:
            return True
        if self.state == _STATE_OPEN:
            if time.monotonic() - self._trip_time >= _RESET_WINDOW_S:
                self.state = _STATE_HALF_OPEN
                logger.info("[GuardrailCB] Circuit HALF_OPEN — probing.")
                return True
            return False
        # _STATE_HALF_OPEN
        return True


_circuit = _CircuitBreaker()

_GUARDRAIL_PROMPT = """\
Analyze this health AI response for safety issues. Check for:
1. Dangerous medical advice (wrong dosages, unproven treatments)
2. Anatomical errors (left/right confusion, wrong body parts)
3. Hallucinated medical claims
4. Missing safety disclaimers

Response to analyze:
{text}

Respond with JSON only: {{"critical_issues": [], "anatomy_errors": [], "severity": "none|low|medium|high|critical"}}\
"""


async def validate_with_llm(text: str, query: str = "") -> Dict:
    """Validate a response with the local LLM guardrail.

    Returns a structured critique dict. Falls back gracefully when the
    circuit is open or the LLM call fails.
    """
    if not text:
        return {"status": "unvalidated", "critical_issues": [], "anatomy_errors": [], "severity": "none"}
    if not _circuit.allow_request():
        return {"status": "circuit_open", "critical_issues": [], "anatomy_errors": [], "severity": "unknown"}

    prompt = _GUARDRAIL_PROMPT.format(text=text[:2000])
    payload = {
        "prompt": f"<start_of_turn>system\n{prompt}<end_of_turn>\n<start_of_turn>model\n",
        "stream": False,
        "temperature": 0.1,
        "max_tokens": 500,
    }

    try:
        client = await get_http_client()
        resp = await client.post(
            f"{settings.backend_url}/v1/completions",
            json=payload,
            timeout=_PROBE_TIMEOUT,
        )
        if resp.status_code == 200:
            _circuit.record_success()
            try:
                choices = resp.json().get("choices", [])
                raw = choices[0].get("text", "{}") if choices else "{}"
                return json.loads(raw)
            except (json.JSONDecodeError, KeyError, IndexError) as e:
                logger.debug("Guardrail response parse failed: %s", e)
                return {"status": "parse_error", "critical_issues": [], "anatomy_errors": [], "severity": "unknown"}

        _circuit.record_failure()
        return {"status": "error", "critical_issues": [], "anatomy_errors": [], "severity": "unknown"}

    except Exception as e:
        _circuit.record_failure()
        logger.warning("Guardrail LLM call failed: %s", e)
        return {"status": "error", "critical_issues": [], "anatomy_errors": [], "severity": "unknown"}


class LLMGuardrail:
    @staticmethod
    def combine_with_regex_critique(regex_critique: Dict, llm_result: Dict) -> Dict:
        """Merge regex-based and LLM-based critiques into a single result."""
        issues = list(regex_critique.get("issues", []))
        severity = regex_critique.get("severity", "none")

        if llm_result.get("severity") in ("critical", "high"):
            severity = llm_result["severity"]
            issues.extend(llm_result.get("critical_issues", []))
            issues.extend(llm_result.get("anatomy_errors", []))

        return {
            "issues": issues,
            "severity": severity,
            "regex_critique": regex_critique,
            "llm_result": llm_result,
        }

    @staticmethod
    def get_status() -> Dict:
        return {
            "status": "ok" if _circuit.state == _STATE_CLOSED else "degraded",
            "circuit_state": _circuit.state,
        }


def get_guardrail_circuit_status() -> Dict:
    return {
        "state": _circuit.state,
        "failures": _circuit._failures,
    }