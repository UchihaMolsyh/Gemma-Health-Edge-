"""Gemma Health Edge — Research Engine.

Fetches real-time medical context from Wikipedia and PubMed to ground
AI responses in authoritative sources. Results are cached to avoid
redundant network calls for repeated queries.
"""
import asyncio
import hashlib
import logging
import re
import urllib.parse
from typing import Optional

import httpx

from cache import research_cache
from config import get_http_client, settings

logger = logging.getLogger("ghe.middleman.research")

# ── API Endpoints ─────────────────────────────────────────────────────────────
_WIKI_API      = "https://en.wikipedia.org/api/rest_v1/page/summary"
_PUBMED_SEARCH = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
_PUBMED_FETCH  = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"
_USER_AGENT    = "GemmaHealthEdge/2.0 (https://github.com/gemma-health-edge)"

# ── Medical keyword trigger set ───────────────────────────────────────────────
_MEDICAL_KEYWORDS = frozenset({
    "symptom", "pain", "dose", "medicine", "treatment", "drug", "disease",
    "health", "rash", "wound", "blood", "heart", "fever", "cough", "infection",
    "allergy", "injury", "burn", "swelling", "nausea", "dizzy", "fracture",
    "virus", "flu", "cold", "covid", "vomit", "brain", "skin", "organ", "cure",
    "medical", "doctor", "ache", "headache", "stomach", "chest", "back",
    "throat", "eye", "ear", "tooth", "muscle", "joint", "bone", "nerve",
    "lung", "liver", "kidney", "diabetes", "asthma", "cancer", "stroke",
    "anxiety", "depression", "insomnia", "vitamin", "mineral", "protein",
    "calorie", "nutrition", "diet", "exercise", "sleep", "stress", "pressure",
    "pulse", "oxygen", "temperature", "weight", "bmi", "ibuprofen", "aspirin",
    "paracetamol", "antibiotic", "vaccine", "surgery", "therapy", "clinic",
    "hospital", "patient", "pharmacy", "dosage", "prescription", "side",
    "effect", "allergen", "toxic",
})

_NON_WORD = re.compile(r"[^\w\s-]")


def is_medical_query(text: str | list) -> bool:
    """Return True if the text contains at least one medical keyword."""
    if not text:
        return False
    if isinstance(text, list):
        text = " ".join(str(item) for item in text)
    words = set(_NON_WORD.sub("", text.lower()).split())
    return bool(words & _MEDICAL_KEYWORDS)


async def fetch_wikipedia(query: str) -> Optional[str]:
    """Fetch the Wikipedia summary for a medical term."""
    if not query or not query.strip():
        return None
    try:
        client = await get_http_client()
        resp = await client.get(
            f"{_WIKI_API}/{urllib.parse.quote(query)}",
            headers={"User-Agent": _USER_AGENT},
            timeout=httpx.Timeout(settings.research_timeout, connect=settings.research_timeout, read=settings.research_timeout, write=settings.research_timeout, pool=settings.research_timeout),
        )
        if resp.status_code == 200:
            data = resp.json()
            title   = data.get("title", query)
            extract = data.get("extract", "")
            if not extract:
                return None
            return f"**{title}**\n{extract}"
    except (httpx.TimeoutException, httpx.ConnectError) as e:
        logger.debug("Wikipedia fetch failed (network): %s", e)
    except Exception as e:
        logger.debug("Wikipedia fetch failed: %s", e)
    return None


async def fetch_pubmed(query: str) -> Optional[str]:
    """Fetch up to 2 PubMed abstracts for a medical query."""
    if not query or not query.strip():
        return None
    try:
        client = await get_http_client()
        timeout = httpx.Timeout(settings.research_timeout, connect=settings.research_timeout, read=settings.research_timeout, write=settings.research_timeout, pool=settings.research_timeout)

        search = await client.get(
            _PUBMED_SEARCH,
            params={"db": "pubmed", "term": query, "retmode": "json", "retmax": 3},
            timeout=timeout,
        )
        if search.status_code != 200:
            return None

        ids = search.json().get("esearchresult", {}).get("idlist", [])
        if not ids:
            return None

        fetch = await client.get(
            _PUBMED_FETCH,
            params={"db": "pubmed", "id": ",".join(ids), "retmode": "xml", "rettype": "abstract"},
            timeout=timeout,
        )
        if fetch.status_code != 200:
            return None

        abstracts = re.findall(r"<AbstractText[^>]*>([^<]+)</AbstractText>", fetch.text)
        if abstracts:
            return "**PubMed:**\n" + "\n\n".join(abstracts[:2])

    except (httpx.TimeoutException, httpx.ConnectError) as e:
        logger.debug("PubMed fetch failed (network): %s", e)
    except Exception as e:
        logger.debug("PubMed fetch failed: %s", e)
    return None


async def fetch_research_context(query: str) -> Optional[str]:
    """Return a combined Wikipedia + PubMed research snippet for a query.

    Results are cached for ``settings.cache_ttl`` seconds to avoid
    hammering external APIs on repeated identical queries.
    """
    if not query or not query.strip():
        return None
    if not is_medical_query(query):
        return None

    cache_key = hashlib.md5(query.encode()).hexdigest()
    cached = research_cache.get(cache_key)
    if cached:
        return cached

    try:
        wiki, pubmed = await asyncio.gather(
            fetch_wikipedia(query),
            fetch_pubmed(query),
            return_exceptions=True,
        )
        if isinstance(wiki, Exception):
            logger.debug("Wikipedia task raised: %s", wiki)
            wiki = None
        if isinstance(pubmed, Exception):
            logger.debug("PubMed task raised: %s", pubmed)
            pubmed = None

        parts = [p for p in (wiki, pubmed) if p]
        if parts:
            result = "\n\n".join(parts)
            research_cache[cache_key] = result
            return result

    except Exception as e:
        logger.warning("fetch_research_context failed: %s", e)

    return None