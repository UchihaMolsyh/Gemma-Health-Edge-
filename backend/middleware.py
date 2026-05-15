"""Gemma Health Edge — MiddleMan Middleware.

Configures CORS, per-request timing/logging, and a global error handler
so all unhandled exceptions return clean JSON rather than raw tracebacks.
"""
import logging
import time

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from config import settings

logger = logging.getLogger("ghe.middleman")


def setup_middleware(app: FastAPI) -> None:
    """Attach all middleware to the FastAPI application."""

    # ── CORS ──────────────────────────────────────────────────────────────────
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["*"],
        expose_headers=["X-Accel-Buffering", "Cache-Control"],
        max_age=600,
    )

    # ── Request logging + security headers ────────────────────────────────────
    @app.middleware("http")
    async def log_requests(request: Request, call_next):
        start    = time.time()
        response = await call_next(request)
        duration = round((time.time() - start) * 1000)

        response.headers.setdefault("X-Content-Type-Options", "nosniff")
        response.headers.setdefault("Referrer-Policy",        "no-referrer")
        response.headers.setdefault("X-Frame-Options",        "DENY")
        response.headers.setdefault(
            "Permissions-Policy",
            "camera=(self), microphone=(self), geolocation=()",
        )

        if request.url.path.startswith("/api/"):
            logger.info(
                "%s %s → %d (%dms)",
                request.method, request.url.path, response.status_code, duration,
            )
        return response

    # ── Global error handler ──────────────────────────────────────────────────
    @app.exception_handler(Exception)
    async def global_error_handler(request: Request, exc: Exception):
        logger.error("Unhandled error on %s: %s", request.url.path, exc, exc_info=True)
        detail = str(exc) if settings.debug else ""
        return JSONResponse(
            status_code=500,
            content={"error": "Internal server error", "detail": detail},
        )
