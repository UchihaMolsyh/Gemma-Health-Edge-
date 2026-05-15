"""
Gemma Health Edge — Research Engine Tests
Tests for Wikipedia + PubMed medical context fetching.
"""
import pytest
from unittest.mock import AsyncMock, Mock, patch

from research import (
    is_medical_query,
    fetch_research_context,
    fetch_wikipedia,
    fetch_pubmed,
)


class TestMedicalQueryDetection:
    def test_detects_symptom(self):
        assert is_medical_query("I have a headache and fever") is True

    def test_detects_medication(self):
        assert is_medical_query("What is the dosage for ibuprofen?") is True

    def test_detects_disease(self):
        assert is_medical_query("Symptoms of diabetes") is True

    def test_detects_body_part(self):
        assert is_medical_query("Pain in my chest") is True

    def test_rejects_non_medical(self):
        assert is_medical_query("What's the weather today?") is False

    def test_rejects_empty(self):
        assert is_medical_query("") is False
        assert is_medical_query(None) is False

    def test_handles_list_content(self):
        assert is_medical_query(["headache", "fever"]) is True

    def test_case_insensitive(self):
        assert is_medical_query("HEADACHE and FEVER") is True


class TestWikipediaFetch:
    @pytest.mark.asyncio
    @patch("research.get_http_client", new_callable=AsyncMock)
    async def test_successful_fetch(self, mock_get_client):
        mock_client = AsyncMock()
        mock_response = Mock(spec=["status_code", "json"])
        mock_response.status_code = 200
        mock_response.json = Mock(return_value={"extract": "Aspirin is a medication.", "title": "Aspirin"})
        mock_client.get.return_value = mock_response
        mock_get_client.return_value = mock_client

        result = await fetch_wikipedia("aspirin")
        assert result is not None
        assert "medication" in result.lower()

    @pytest.mark.asyncio
    @patch("research.get_http_client", new_callable=AsyncMock)
    async def test_empty_response(self, mock_get_client):
        mock_client = AsyncMock()
        mock_response = Mock(spec=["status_code", "json"])
        mock_response.status_code = 200
        mock_response.json = Mock(return_value={"extract": "", "title": "Aspirin"})
        mock_client.get.return_value = mock_response
        mock_get_client.return_value = mock_client

        result = await fetch_wikipedia("aspirin")
        assert result is None

    @pytest.mark.asyncio
    @patch("research.get_http_client", new_callable=AsyncMock)
    async def test_error_response(self, mock_get_client):
        mock_client = AsyncMock()
        mock_response = Mock(spec=["status_code"])
        mock_response.status_code = 404
        mock_client.get.return_value = mock_response
        mock_get_client.return_value = mock_client

        result = await fetch_wikipedia("xyz123")
        assert result is None


class TestPubMedFetch:
    @pytest.mark.asyncio
    @patch("research.get_http_client", new_callable=AsyncMock)
    async def test_successful_fetch(self, mock_get_client):
        mock_client = AsyncMock()

        search_response = Mock(spec=["status_code", "json"])
        search_response.status_code = 200
        search_response.json = Mock(return_value={"esearchresult": {"idlist": ["12345"]}})

        fetch_response = Mock(spec=["status_code", "text"])
        fetch_response.status_code = 200
        fetch_response.text = "<AbstractText>Aspirin reduces inflammation.</AbstractText>"

        mock_client.get.side_effect = [search_response, fetch_response]
        mock_get_client.return_value = mock_client

        result = await fetch_pubmed("aspirin inflammation")
        assert result is not None
        assert "Aspirin" in result

    @pytest.mark.asyncio
    @patch("research.get_http_client", new_callable=AsyncMock)
    async def test_no_results(self, mock_get_client):
        mock_client = AsyncMock()
        search_response = Mock(spec=["status_code", "json"])
        search_response.status_code = 200
        search_response.json = Mock(return_value={"esearchresult": {"idlist": []}})
        mock_client.get.return_value = search_response
        mock_get_client.return_value = mock_client

        result = await fetch_pubmed("xyz123abc")
        assert result is None


class TestResearchContextIntegration:
    @pytest.mark.asyncio
    async def test_skips_non_medical(self):
        result = await fetch_research_context("What's the weather?")
        assert result is None

    @pytest.mark.asyncio
    @patch("research.fetch_wikipedia")
    @patch("research.fetch_pubmed")
    async def test_combines_sources(self, mock_pubmed, mock_wiki):
        mock_wiki.return_value = "Wikipedia: Aspirin is a pain reliever."
        mock_pubmed.return_value = "PubMed: Abstract about aspirin."

        result = await fetch_research_context("aspirin for pain")
        assert "Wikipedia" in result
        assert "PubMed" in result

    @pytest.mark.asyncio
    @patch("research.fetch_wikipedia")
    @patch("research.fetch_pubmed")
    async def test_handles_partial_failure(self, mock_pubmed, mock_wiki):
        mock_wiki.return_value = "Wikipedia content"
        mock_pubmed.return_value = None

        result = await fetch_research_context("headache treatment")
        assert "Wikipedia" in result
        assert "PubMed" not in result

    @pytest.mark.asyncio
    @patch("research.fetch_wikipedia")
    @patch("research.fetch_pubmed")
    async def test_caches_results(self, mock_pubmed, mock_wiki):
        mock_wiki.return_value = "Cached content"
        mock_pubmed.return_value = None

        query = "headache unique cache test query"
        result1 = await fetch_research_context(query)
        result2 = await fetch_research_context(query)

        assert mock_wiki.call_count == 1
