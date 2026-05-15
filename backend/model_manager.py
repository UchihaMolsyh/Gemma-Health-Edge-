"""Gemma Health Edge — Model Manager.

Manages the lifecycle of the local llama-server process:
start, stop, health-check, and hardware-aware flag derivation.
"""
import logging
import os
import subprocess
import threading
from pathlib import Path

from hardware_detector import HardwareDetector

logger = logging.getLogger("ghe.backend.model_manager")

_vision_supported = False


def get_vision_supported() -> bool:
    if _vision_supported:
        return True
    return True


class ModelManager:
    """Manages a single llama-server subprocess."""

    DEFAULT_MODEL = "gemma-4-E4B-it-Q4_K_M.gguf"
    DEFAULT_PORT  = 8081
    CONTEXT_SIZE  = "32768"
    GPU_LAYERS    = "99"

    def __init__(self, config: dict | None = None) -> None:
        self.config = config or {}
        self.process: subprocess.Popen | None = None
        self.log_file = None
        self._lock = threading.Lock()
        self._shutdown = False

        self.backend_dir = Path(__file__).parent.resolve()
        self.llama_dir   = self.backend_dir / "llama-server"
        self.models_dir  = self.backend_dir / "models"

        cfg_exe = self.config.get("llama_server_path")
        if cfg_exe:
            self.exe_path = (self.backend_dir / cfg_exe).resolve()
        else:
            exe_name = "llama-server.exe" if os.name == "nt" else "llama-server"
            self.exe_path = self.llama_dir / exe_name

    # ── Public API ────────────────────────────────────────────────────────────

    def check_executable(self) -> bool:
        """Return True if the llama-server binary exists and is non-empty."""
        return self.exe_path.exists() and self.exe_path.stat().st_size > 0

    def start_server(self, model_name: str | None = None) -> bool:
        """Start llama-server if not already running."""
        with self._lock:
            if self._shutdown:
                logger.warning("Cannot start — shutdown already in progress.")
                return False
            if self.process and self.process.poll() is None:
                logger.info("llama-server already running (pid %d).", self.process.pid)
                return True
            return self._do_start(model_name)

    def stop_server(self) -> None:
        """Gracefully terminate llama-server; force-kill on timeout."""
        with self._lock:
            if not self.process:
                return
            self._shutdown = True
            logger.info("Shutting down llama-server (pid %d)…", self.process.pid)
            self.process.terminate()
            try:
                self.process.wait(timeout=15)
                logger.info("llama-server terminated gracefully.")
            except subprocess.TimeoutExpired:
                logger.warning("Timeout — force-killing llama-server.")
                self.process.kill()
            finally:
                if self.log_file:
                    self.log_file.close()
                    self.log_file = None
                self.process = None
                logger.info("llama-server stopped.")

    def is_running(self) -> bool:
        return self.process is not None and self.process.poll() is None

    def get_status(self) -> dict:
        return {
            "running": self.is_running(),
            "pid": self.process.pid if self.process else None,
        }

    # ── Internal ──────────────────────────────────────────────────────────────

    def _do_start(self, model_name: str | None = None) -> bool:
        if not self.check_executable():
            logger.error("llama-server not found at: %s", self.exe_path)
            return False

        model = model_name or self.config.get("model", self.DEFAULT_MODEL)
        model_path = self.models_dir / model
        if not model_path.exists():
            logger.error("Model file not found: %s", model_path)
            return False

        hw = HardwareDetector.detect()
        threads = hw.get("max_threads", 8)

        args = [
            str(self.exe_path),
            "-m", str(model_path),
            "-c", self.CONTEXT_SIZE,
            "--threads", str(threads),
            "--port", str(self.DEFAULT_PORT),
        ]
        if hw.get("accelerator") != "cpu":
            args.extend(["--gpu-layers", self.GPU_LAYERS])

        global _vision_supported
        mmproj = self._derive_mmproj(model)
        if mmproj:
            _vision_supported = True
            args.extend(["--mmproj", str(mmproj)])

        try:
            log_path = self.backend_dir / "llama-server.log"
            self.log_file = open(log_path, "w", encoding="utf-8")  # noqa: WPS515
        except OSError as e:
            logger.error("Cannot open llama-server log file: %s", e)
            return False

        self.process = subprocess.Popen(args, stdout=self.log_file, stderr=subprocess.STDOUT)
        logger.info("llama-server started on port %d with %d threads.", self.DEFAULT_PORT, threads)
        return True

    def _derive_mmproj(self, model_name: str) -> Path | None:
        """Attempt to locate the matching mmproj vision file for a model."""
        candidates = [
            model_name.replace("-Q4_K_M", "-bf16"),
            model_name.replace("-Q4_K_M.gguf", "-bf16.gguf"),
            model_name.replace("-Q4_0", "-bf16"),
            model_name.replace("-Q4_0.gguf", "-bf16.gguf"),
            model_name.replace(".gguf", "-bf16.gguf"),
        ]
        for cand in candidates:
            p = self.models_dir / f"mmproj-{cand}"
            if p.exists():
                return p
        return None


if __name__ == "__main__":
    mgr = ModelManager()
    print(f"Executable exists: {mgr.check_executable()}")
    print(f"Status: {mgr.get_status()}")