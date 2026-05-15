"""
Gemma Health Edge — MiddleMan Gateway v2.0
"""
import logging
import os
import socket
import subprocess
import threading
from contextlib import asynccontextmanager
from pathlib import Path

import uvicorn
from fastapi import FastAPI

from config import settings, close_http_client
from router import api_router
from database import init_database
from middleware import setup_middleware
from auth import setup_rate_limiting
from concurrent.futures import ThreadPoolExecutor

logging.basicConfig(
    level=getattr(logging, settings.log_level.upper(), logging.INFO),
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("ghe.middleman")

thread_pool = ThreadPoolExecutor(max_workers=settings.max_workers)

OLLAMA_PORT = 11434


def _port_open(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(("127.0.0.1", port)) == 0


def _start_ollama():
    if _port_open(OLLAMA_PORT):
        logger.info("Ollama already running on port %d.", OLLAMA_PORT)
        return

    exe_name = "ollama.exe" if os.name == "nt" else "ollama"
    if os.name == "nt":
        candidates = [exe_name, os.path.expandvars(r"%LOCALAPPDATA%\Programs\Ollama\ollama.exe")]
    else:
        candidates = [exe_name, "/usr/local/bin/ollama", "/usr/bin/ollama"]

    exe_path = None
    for p in candidates:
        if p and Path(p).exists():
            exe_path = p
            break
        if p and os.name == "nt":
            try:
                subprocess.run([p, "--version"], capture_output=True, timeout=3)
                exe_path = p
                break
            except (FileNotFoundError, subprocess.SubprocessError):
                continue

    if not exe_path:
        logger.info("Ollama not found. Install from https://ollama.com to use Ollama mode.")
        return

    try:
        proc = subprocess.Popen([exe_path, "serve"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(10):
            import time as _t
            _t.sleep(0.5)
            if _port_open(OLLAMA_PORT):
                logger.info("Ollama started on port %d.", OLLAMA_PORT)
                return
        logger.warning("Ollama binary found but failed to start on port %d.", OLLAMA_PORT)
        proc.terminate()
    except Exception as e:
        logger.debug("Failed to start Ollama: %s", e)


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_database()
    _start_ollama()
    logger.info("Gemma Health Edge MiddleMan v2.0")
    logger.info("   Host:       %s:%d", settings.host, settings.port)
    logger.info("   Backend:    %s", settings.backend_url)
    logger.info("   Static:     %s", settings.static_dir)
    logger.info("   Model:      Gemma 4 ONLY")
    logger.info("   Research:   Wikipedia + PubMed")
    logger.info("   CORS:       %s", settings.allowed_origins)
    logger.info("   Workers:    %d", settings.max_workers)
    logger.info("   Pool Size:  %d", settings.connection_pool_size)

    yield

    logger.info("MiddleMan shutting down...")
    thread_pool.shutdown(wait=True)
    try:
        await close_http_client()
        logger.info("   HTTP client closed")
    except Exception as e:
        logger.warning("   Error closing HTTP client: %s", e)
    logger.info("   Shutdown complete.")


# ── App ──────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="Gemma Health Edge MiddleMan",
    version="2.0.0",
    description="Gateway between frontends and the AI backend. Gemma 4 models only.",
    lifespan=lifespan,
)

# API routes
app.include_router(api_router, prefix="/api/v1")

# Data routes (sessions, moods, clinical profile) - replaces frontend storage
from api_data import data_router
app.include_router(data_router, prefix="/api/v1")

# Middleware (must be added after routes for proper CORS handling)
setup_middleware(app)
setup_rate_limiting(app)

# Static file serving (PC frontend) — replaces simple_server.js
from fastapi.staticfiles import StaticFiles

# Resolve static path relative to this file's location
# Backend is in /backend, frontend is in /frontend/pc
static_path = (Path(__file__).parent.parent / "frontend" / "pc").resolve()
if static_path.exists():
    app.mount("/", StaticFiles(directory=str(static_path), html=True), name="static")
    logger.info("   Serving static files from: %s", static_path)
else:
    # Fallback: try the configured path
    static_path = Path(settings.static_dir).resolve()
    if static_path.exists():
        app.mount("/", StaticFiles(directory=str(static_path), html=True), name="static")
        logger.info("   Serving static files from: %s", static_path)
    else:
        logger.warning("   Static dir not found: %s (frontend won't be served)", static_path)


# ── Entry Point ──────────────────────────────────────────────────────────────
if __name__ == "__main__":
    uvicorn.run(
        "gateway:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level=settings.log_level.lower(),
    )
