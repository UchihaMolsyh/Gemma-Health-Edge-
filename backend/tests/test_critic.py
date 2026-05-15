"""
Gemma Health Edge — Response Critic Tests
Comprehensive tests for the hallucination and safety detection system.
"""
import pytest
from critic import ResponseCritic, critique_response


class TestAnatomicalErrors:
    def test_left_hand_on_right(self):
        text = "The patient's left hand is on the right side"
        result = ResponseCritic.analyze(text)
        assert any("Anatomical contradiction" in i for i in result["issues"])

    def test_heart_right_side(self):
        text = "The human heart is located on the right side of the chest"
        result = ResponseCritic.analyze(text)
        assert any("heart" in i.lower() for i in result["issues"])
        assert result["severity"] in ("critical", "high")

    def test_liver_left_side(self):
        text = "The liver is on the left side"
        result = ResponseCritic.analyze(text)
        assert any("liver" in i.lower() for i in result["issues"])

    def test_clean_anatomy(self):
        text = "The heart is on the left side and the liver is on the right side"
        result = ResponseCritic.analyze(text)
        assert len(result["issues"]) == 0


class TestHallucinationDetection:
    def test_cancer_cure_claim(self):
        text = "This natural herb cures all cancer completely and is 100% effective"
        result = ResponseCritic.analyze(text)
        assert any("hallucination" in i.lower() for i in result["issues"])

    def test_vaccine_autism_claim(self):
        text = "Vaccines cause autism in children"
        result = ResponseCritic.analyze(text)
        assert any("vaccine" in i.lower() for i in result["issues"])

    def test_miracle_cure_language(self):
        text = "This miracle cure will heal all diseases instantly"
        result = ResponseCritic.analyze(text)
        assert any("miracle" in i.lower() for i in result["issues"])

    def test_doctors_hide_cures(self):
        text = "Doctors don't want you to know about this secret treatment"
        result = ResponseCritic.analyze(text)
        assert any("conspiracy" in i.lower() for i in result["issues"])


class TestSafetyCritical:
    def test_stop_medication(self):
        text = "You should stop taking your insulin immediately"
        result = ResponseCritic.analyze(text)
        assert result["severity"] == "critical"

    def test_avoid_doctor(self):
        text = "Don't see a doctor for this condition"
        result = ResponseCritic.analyze(text)
        assert result["severity"] == "critical"

    def test_self_diagnosis(self):
        text = "You can self-diagnose cancer at home"
        result = ResponseCritic.analyze(text)
        assert any("self-diagnos" in i.lower() for i in result["issues"])


class TestSeverityLevels:
    def test_critical_severity(self):
        text = "Stop taking your prescribed medication and don't consult your doctor"
        result = ResponseCritic.analyze(text)
        assert result["severity"] == "critical"

    def test_high_severity(self):
        text = "The heart is on the right side of the body"
        result = ResponseCritic.analyze(text)
        assert result["severity"] in ("critical", "high")


class TestBlockingLogic:
    def test_block_critical(self):
        critique = {"issues": ["CRITICAL: Advising to stop prescribed medication"], "severity": "critical"}
        should_block, reason = ResponseCritic.should_block_response(critique)
        assert should_block is True

    def test_allow_clean_response(self):
        critique = {"issues": [], "severity": "none"}
        should_block, reason = ResponseCritic.should_block_response(critique)
        assert should_block is False


class TestConvenienceFunction:
    def test_wrapper_returns_dict(self):
        result = critique_response("Safe medical advice. Always consult a doctor.")
        assert isinstance(result, dict)
        assert "issues" in result
        assert "severity" in result

    def test_wrapper_handles_empty(self):
        result = critique_response("")
        assert len(result["issues"]) == 0
        assert result["severity"] == "none"
