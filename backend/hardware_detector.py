"""Gemma Health Edge — Hardware Detector.

Detects the best available compute accelerator (CUDA GPU, Apple Metal,
Qualcomm/Intel NPU, Google TPU) and returns a normalised info dict for
use by the model manager and health endpoints.
"""
import logging
import os
import platform
import subprocess
from pathlib import Path

logger = logging.getLogger("ghe.backend.hardware")


class HardwareDetector:
    @staticmethod
    def detect() -> dict:
        """Detect the best available accelerator.

        Returns a dict with keys:
            gpu, vram_gb, has_cuda, has_rocm, has_vulkan, has_npu,
            has_tpu, has_metal, cpu_total_threads, max_threads, accelerator
        """
        cpu_total = os.cpu_count() or 4
        info = {
            "gpu": "CPU Only",
            "vram_gb": 0,
            "has_cuda": False,
            "has_rocm": False,
            "has_vulkan": False,
            "has_npu": False,
            "has_tpu": False,
            "has_metal": platform.system() == "Darwin",
            "cpu_total_threads": cpu_total,
            "max_threads": max(1, cpu_total // 2),
            "accelerator": "cpu",
        }

        # ── TPU (Linux only) ─────────────────────────────────────────────────
        if platform.system() == "Linux" and list(Path("/dev").glob("apex_*")):
            info["has_tpu"] = True
            info["accelerator"] = "tpu"
            return info

        # ── NVIDIA CUDA ───────────────────────────────────────────────────────
        try:
            result = subprocess.run(
                ["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader,nounits"],
                capture_output=True, text=True, timeout=5,
            )
            if result.returncode == 0 and result.stdout.strip():
                line = result.stdout.strip().split("\n")[0]
                parts = line.split(",")
                info["has_cuda"] = True
                info["accelerator"] = "cuda"
                if len(parts) >= 2:
                    info["gpu"] = parts[0].strip()
                    try:
                        info["vram_gb"] = round(float(parts[1].strip()) / 1024, 1)
                    except ValueError:
                        pass
                else:
                    info["gpu"] = "NVIDIA GPU"
                return info
        except (subprocess.TimeoutExpired, subprocess.SubprocessError, FileNotFoundError) as e:
            logger.debug("NVIDIA detection failed: %s", e)

        # ── Apple Metal (Silicon) ─────────────────────────────────────────────
        if platform.system() == "Darwin":
            try:
                result = subprocess.run(
                    ["sysctl", "-n", "machdep.cpu.brand_string"],
                    capture_output=True, text=True, timeout=2,
                )
                if "Apple" in result.stdout:
                    info["has_metal"] = True
                    info["accelerator"] = "metal"
                    info["gpu"] = "Apple Silicon"
                    return info
            except (subprocess.TimeoutExpired, subprocess.SubprocessError, FileNotFoundError) as e:
                logger.debug("Metal detection failed: %s", e)

        # ── NPU (Windows — last resort, checked after GPU) ─────────────────────
        if platform.system() == "Windows":
            try:
                result = subprocess.run(
                    [
                        "powershell", "-Command",
                        "Get-CimInstance Win32_PnPEntity | Where-Object { ($_.Name -match '\\bNPU\\b|Neural Processor|AI Accelerator|AI Boost') -and ($_.Name -notmatch 'USB') }",
                    ],
                    capture_output=True, text=True, timeout=5,
                )
                if result.stdout.strip():
                    info["has_npu"] = True
                    info["accelerator"] = "npu"
                    return info
            except (subprocess.TimeoutExpired, subprocess.SubprocessError, FileNotFoundError) as e:
                logger.debug("NPU detection failed: %s", e)

        return info

    @staticmethod
    def get_llama_args() -> list:
        """Return the llama-server CLI flags appropriate for this hardware."""
        hw = HardwareDetector.detect()
        args = ["--threads", str(hw["max_threads"])]
        if hw["accelerator"] in ("cuda", "metal"):
            args.extend(["--gpu-layers", "99"])
        return args


if __name__ == "__main__":
    import json as _json
    print(_json.dumps(HardwareDetector.detect(), indent=2))