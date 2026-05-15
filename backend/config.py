"""Gemma Health Edge — MiddleMan Configuration.

All settings are loaded from environment variables (prefixed GHE_) or a
local .env file. A shared httpx.AsyncClient with connection pooling is
provided via get_http_client() to avoid per-request connection overhead.
"""
import asyncio
import logging
from pathlib import Path
from typing import Optional

import httpx
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger("ghe.middleman.config")


class Settings(BaseSettings):
    # ── Server ────────────────────────────────────────────────────────────────
    host:      str  = "127.0.0.1"
    port:      int  = 8080
    debug:     bool = True
    log_level: str  = "INFO"

    # ── CORS ──────────────────────────────────────────────────────────────────
    allowed_origins: list[str] = ["*"]

    # ── Request limits ────────────────────────────────────────────────────────
    max_request_body_size: int = 10 * 1024 * 1024   # 10 MB
    max_image_size:        int =  8 * 1024 * 1024   #  8 MB

    # ── Backend URLs ──────────────────────────────────────────────────────────
    backend_url:  str = "http://127.0.0.1:8081"
    ollama_url:   str = "http://127.0.0.1:11434"

    # ── Timeouts ──────────────────────────────────────────────────────────────
    backend_timeout:  float = 300.0
    research_timeout: float = 3.0

    # ── Static files ──────────────────────────────────────────────────────────
    static_dir: str = str(Path(__file__).parent.parent / "frontend" / "pc")

    # ── API keys ──────────────────────────────────────────────────────────────
    google_api_key:     str = ""
    openrouter_api_key: str = ""

    # ── Rate limiting ─────────────────────────────────────────────────────────
    rate_limit: str = "200/minute"

    # ── Model policy ─────────────────────────────────────────────────────────
    model: str = "gemma-4-e4b-it-Q4_K_M.gguf"

    # ── Cache ─────────────────────────────────────────────────────────────────
    cache_max_size: int = 500
    cache_ttl:      int = 7200   # 2 hours

    # ── Connection pool ───────────────────────────────────────────────────────
    max_workers:           int   = 4
    connection_pool_size:  int   = 20
    keepalive_timeout:     float = 30.0
    enable_compression:    bool  = True
    max_concurrent_requests: int = 100

    @field_validator("allowed_origins", mode="before")
    @classmethod
    def _parse_origins(cls, v):
        if isinstance(v, str):
            return [o.strip() for o in v.split(",") if o.strip()]
        return v

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        env_prefix="GHE_",
        extra="ignore",
    )


def validate_api_key(api_key: str, provider: str) -> bool:
    """Return True if the API key passes basic format validation."""
    if not api_key or not api_key.strip():
        return False
    key = api_key.strip()
    if provider == "google":
        return len(key) >= 30 and key.startswith("AIza")
    if provider == "openrouter":
        return len(key) >= 40 and key.startswith("sk-or-v1-")
    return len(key) >= 20


settings = Settings()

# ── Shared HTTP client with async-safe initialisation ─────────────────────────

_http_client: Optional[httpx.AsyncClient] = None
_http_client_lock = asyncio.Lock()


async def get_http_client() -> httpx.AsyncClient:
    """Return the shared AsyncClient, creating it on first call."""
    global _http_client
    if _http_client is None:
        async with _http_client_lock:
            if _http_client is None:
                _http_client = httpx.AsyncClient(
                    timeout=httpx.Timeout(
                        connect=5.0,
                        read=settings.backend_timeout,
                        write=10.0,
                        pool=settings.keepalive_timeout,
                    ),
                    limits=httpx.Limits(
                        max_keepalive_connections=settings.connection_pool_size,
                        max_connections=settings.max_concurrent_requests,
                    ),
                    http2=False,
                    headers={"Accept-Encoding": "gzip, deflate"} if settings.enable_compression else None,
                )
    return _http_client


async def close_http_client() -> None:
    """Cleanly close the shared HTTP client on shutdown."""
    global _http_client
    if _http_client:
        try:
            await _http_client.aclose()
        except Exception as e:
            logger.warning("Error closing HTTP client: %s", e)
        _http_client = None