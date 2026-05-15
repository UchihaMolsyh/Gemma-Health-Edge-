"""Gemma Health Edge — Research Cache.

Provides a TTL (Time-To-Live) cache for research results to avoid
redundant external API calls and improve response latency.
"""
from cachetools import TTLCache
from config import settings

# Research results cached based on settings (default 2 hours, 500 entries)
research_cache: TTLCache = TTLCache(
    maxsize=settings.cache_max_size,
    ttl=settings.cache_ttl,
)
