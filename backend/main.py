"""Gemma Health Edge — Backend Entry Point.

Orchestrates the lifecycle of the local AI environment by:
1. Loading configuration from config.json.
2. Initializing the local llama-server (Inference Engine).
3. Starting the FastAPI Middleman (Gateway) for client connectivity.
4. Starting Ollama if installed (for Ollama backend mode).
5. Monitoring system health and handling graceful shutdowns.
"""
import json
import logging
import os
import signal
import socket
import subprocess
import threading
import time
from pathlib import Path

from uvicorn import Config, Server

from model_manager import ModelManager

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("ghe.backend")


def load_config() -> dict:
    config_path = Path(__file__).parent / "config.json"
    if config_path.exists():
        try:
            with open(config_path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            logger.error("Failed to load config.json: %s", e)
    return {"web_port": 8080, "require_local_model": True}


OLLAMA_PORT = 11434


def _port_open(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(("127.0.0.1", port)) == 0


class OllamaManager:
    def __init__(self):
        self.process: subprocess.Popen | None = None

    def start(self) -> bool:
        if _port_open(OLLAMA_PORT):
            logger.info("Ollama already running on port %d.", OLLAMA_PORT)
            return True

        exe_name = "ollama.exe" if os.name == "nt" else "ollama"
        if os.name == "nt":
            paths = [exe_name, os.path.expandvars(r"%LOCALAPPDATA%\Programs\Ollama\ollama.exe")]
        else:
            paths = [exe_name, "/usr/local/bin/ollama", "/usr/bin/ollama"]

        exe_path = None
        for p in paths:
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
            logger.warning("Ollama not found. Install from https://ollama.com to use Ollama mode.")
            return False

        try:
            self.process = subprocess.Popen(
                [exe_path, "serve"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            for _ in range(10):
                time.sleep(0.5)
                if _port_open(OLLAMA_PORT):
                    logger.info("Ollama started on port %d.", OLLAMA_PORT)
                    return True
            logger.warning("Ollama binary found but failed to start on port %d.", OLLAMA_PORT)
            self.stop()
            return False
        except Exception as e:
            logger.warning("Failed to start Ollama: %s", e)
            return False

    def stop(self):
        if self.process:
            try:
                self.process.terminate()
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()
            self.process = None

    def is_running(self) -> bool:
        return _port_open(OLLAMA_PORT)


class GatewayServer:
    def __init__(self, config: dict):
        self.config = config
        self.server: Server | None = None
        self._thread: threading.Thread | None = None

    def start(self):
        web_port = self.config.get("web_port", 8080)
        server_config = Config("gateway:app", host="0.0.0.0", port=web_port, log_level="info")
        self.server = Server(server_config)
        self._thread = threading.Thread(target=self.server.run, daemon=False)
        self._thread.start()
        logger.info("Gateway (FastAPI) listening on port %d", web_port)

    def stop(self, timeout: float = 10.0):
        if self.server:
            self.server.should_exit = True
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=timeout)


def _signal_handler(signum, frame):
    logger.info("Signal %d received, initiating shutdown...", signum)
    raise SystemExit(0)


def main():
    logger.info("Initializing Gemma Health Edge Backend...")

    config = load_config()
    manager = ModelManager(config)
    require_local_model = config.get("require_local_model", True)
    auto_start_ollama = config.get("auto_start_ollama", True)

    if require_local_model:
        max_retries = 3
        for attempt in range(1, max_retries + 1):
            if manager.start_server():
                logger.info("Inference Engine started successfully.")
                break

            logger.warning("Startup attempt %d/%d failed.", attempt, max_retries)
            if attempt < max_retries:
                wait_time = 2 ** attempt
                logger.info("Retrying in %d seconds (exponential backoff)...", wait_time)
                time.sleep(wait_time)
                manager.stop_server()
        else:
            logger.error("Inference Engine failed to start after %d attempts. Aborting.", max_retries)
            return
    else:
        logger.info("Inference Engine bypassed (require_local_model=false). Running in API-only mode.")

    ollama = OllamaManager()
    if auto_start_ollama:
        ollama.start()
    else:
        logger.info("Ollama auto-start disabled (auto_start_ollama=false).")

    signal.signal(signal.SIGINT, _signal_handler)
    signal.signal(signal.SIGTERM, _signal_handler)

    gateway = GatewayServer(config)
    gateway.start()

    logger.info("System fully operational. Press Ctrl+C to stop.")
    try:
        while True:
            time.sleep(2)
            if require_local_model and not manager.is_running():
                logger.error("Inference Engine (llama-server) exited unexpectedly.")
                break
    except (KeyboardInterrupt, SystemExit):
        logger.info("Shutdown signal received.")
    except Exception as e:
        logger.error("Critical error in main loop: %s", e)
    finally:
        logger.info("Performing graceful shutdown...")
        gateway.stop()
        if require_local_model:
            manager.stop_server()
        ollama.stop()
        logger.info("Gemma Health Edge Backend stopped.")


if __name__ == "__main__":
    main()
