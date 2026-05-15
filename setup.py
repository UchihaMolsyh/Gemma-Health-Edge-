#!/usr/bin/env python3
"""
Gemma Health Edge — Auto Setup v2.0
Fixes from v1.1:
  #17 — All HTTP via requests with SSL recovery + timeout handling
New in v2.0:
  #P1 — Already-existing files are verified by size (>1 MB) before skipping
  #P2 — Download resumes if partial file exists (Content-Range)
  #P3 — llama-server DLL dependencies extracted alongside exe
  #P4 — Hugging Face Hub token read from HF_TOKEN env var if set
  #P5 — setup.py is idempotent — safe to re-run at any time
  #P6 — Clear progress bar on completion (no lingering partial line)
"""

import os
import sys
import json
import zipfile
import shutil
import subprocess
from pathlib import Path

BASE_DIR    = Path(__file__).parent.resolve()
CONFIG_PATH = BASE_DIR / "backend" / "config.json"
MODELS_DIR  = BASE_DIR / "backend" / "models"
LLAMA_DIR   = BASE_DIR / "backend" / "llama-server"
TEMP_DIR    = BASE_DIR / ".setup_tmp"

LLAMA_RELEASES_API = "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest"


# ── Helpers ───────────────────────────────────────────────

def print_banner():
    print("\n" + "=" * 60)
    print("  🏥  Gemma Health Edge — Setup v2.0")
    print("  Fully Offline Multimodal Health Assistant")
    print("=" * 60 + "\n")


def load_config():
    if not CONFIG_PATH.exists():
        print(f"❌ config.json not found at {CONFIG_PATH}")
        sys.exit(1)
    with open(CONFIG_PATH) as f:
        return json.load(f)


def ensure_deps():
    # 1. Base setup dependencies
    for pkg in ("requests", "huggingface_hub", "certifi"):
        try:
            __import__(pkg.replace("-", "_"))
            print(f"  ✅ {pkg}")
        except ImportError:
            print(f"  📦 Installing {pkg}…")
            subprocess.check_call([sys.executable, "-m", "pip", "install", pkg, "-q"])
            print(f"  ✅ {pkg} installed")

    # 2. Backend dependencies (requirements.txt)
    backend_req_file = BASE_DIR / "backend" / "requirements.txt"
    if backend_req_file.exists():
        print(f"  📦 Installing backend dependencies from requirements.txt…")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", str(backend_req_file), "-q"])
        print(f"  ✅ Backend dependencies installed")
    else:
        print(f"  ⚠️  backend/requirements.txt not found, skipping backend deps")



# ── HTTP helpers ──────────────────────────────────────────

def _req():
    import importlib
    return importlib.import_module("requests")


def fetch_json(url):
    """GET JSON with SSL recovery using certifi bundle."""
    req = _req()
    hdrs = {"User-Agent": "GemmaHealthEdge/2.0"}
    
    # Try with certifi bundle first (more secure than system certs)
    try:
        import certifi
        ca_bundle = certifi.where()
        r = req.get(url, headers=hdrs, timeout=30, verify=ca_bundle)
        r.raise_for_status()
        return r.json()
    except ImportError:
        pass  # certifi not available, fall back to system verification
    except (req.exceptions.SSLError, req.exceptions.ConnectionError):
        pass  # certifi failed, try system verification
    
    # Try system verification
    try:
        r = req.get(url, headers=hdrs, timeout=30, verify=True)
        r.raise_for_status()
        return r.json()
    except req.exceptions.SSLError as e:
        # Last resort: warn user and try without verification (insecure)
        print("  ⚠️  SSL verification failed. This may indicate:")
        print("     - Outdated system certificates")
        print("     - Corporate proxy with SSL inspection")
        print("     - Man-in-the-middle attack")
        print()
        response = input("  Continue without SSL verification? (NOT RECOMMENDED) [y/N]: ")
        if response.lower() != 'y':
            raise RuntimeError("SSL verification required for security. Aborting.")
        print("  ⚠️  Proceeding without SSL verification (INSECURE)...")
        try:
            r = req.get(url, headers=hdrs, timeout=30, verify=False)
            r.raise_for_status()
            return r.json()
        except Exception as e2:
            raise RuntimeError(f"Request failed even without SSL: {e2}")
    except req.exceptions.ConnectionError as e:
        raise RuntimeError(f"Network error: {e}\n  Check your internet connection.")
    except req.exceptions.Timeout:
        raise RuntimeError("Request timed out (30 s). Check your connection.")
    except req.exceptions.HTTPError as e:
        raise RuntimeError(f"HTTP {e.response.status_code}: {url}")


def download_file(url, dest: Path, desc=""):
    """Stream-download with progress bar. Skips if already complete (#P2 resume)."""
    req = _req()
    hdrs = {"User-Agent": "GemmaHealthEdge/2.0"}

    # Check remote size first
    try:
        head = req.head(url, headers=hdrs, timeout=10, allow_redirects=True)
        remote_size = int(head.headers.get("content-length", 0))
    except Exception:
        remote_size = 0

    # #P1: Skip if dest exists and size matches
    if dest.exists() and remote_size > 0 and dest.stat().st_size >= remote_size * 0.99:
        print(f"  ✅ Already downloaded: {dest.name}")
        return

    # #P2: Partial resume
    resume_pos = dest.stat().st_size if dest.exists() else 0
    if resume_pos > 0 and resume_pos < remote_size:
        hdrs["Range"] = f"bytes={resume_pos}-"
        mode = "ab"
        print(f"  ↩️  Resuming from {resume_pos // (1024*1024):.1f} MB…")
    else:
        mode = "wb"
        resume_pos = 0

    print(f"  ⬇️  Downloading {desc or dest.name}…")
    dest.parent.mkdir(parents=True, exist_ok=True)

    def _get(verify=True):
        return req.get(url, headers=hdrs, stream=True, timeout=90, verify=verify)

    try:
        resp = _get()
        resp.raise_for_status()
    except req.exceptions.SSLError:
        print("  ⚠️  SSL error — retrying without verification…")
        resp = _get(verify=False)
        resp.raise_for_status()
    except req.exceptions.ConnectionError as e:
        raise RuntimeError(f"Download connection error: {e}")

    # If server ignored Range header (returned 200 instead of 206), reset to overwrite
    if resume_pos > 0 and resp.status_code != 206 and "content-range" not in resp.headers:
        mode = "wb"
        resume_pos = 0
        print("  ↩️  Server does not support resume — restarting download…")

    total = resume_pos + int(resp.headers.get("content-length", 0))
    downloaded = resume_pos
    chunk_size = 128 * 1024  # 128 KB

    with open(dest, mode) as f:
        for chunk in resp.iter_content(chunk_size=chunk_size):
            if not chunk:
                continue
            f.write(chunk)
            if total > 0:
                pct = downloaded / total * 100
                mb  = downloaded / (1024 * 1024)
                tmb = total      / (1024 * 1024)
                bar_w = 30
                filled = int(bar_w * downloaded / total)
                bar = "█" * filled + "░" * (bar_w - filled)
                sys.stdout.write(f"\r  [{bar}] {mb:.1f}/{tmb:.1f} MB ({pct:.0f}%)")
                sys.stdout.flush()

    # #P6: Clear progress line
    sys.stdout.write("\r" + " " * 70 + "\r")
    sys.stdout.flush()
    print(f"  ✅ Saved: {dest}")


# ── llama-server ──────────────────────────────────────────

def detect_hardware():
    """Simple hardware detection for setup.py."""
    has_cuda = False
    if sys.platform == "win32":
        paths = [
            os.path.join(os.environ.get("SystemRoot", "C:\\Windows"), "System32", "nvidia-smi.exe"),
            os.path.join(os.environ.get("ProgramFiles", "C:\\Program Files"), "NVIDIA Corporation", "NVSMI", "nvidia-smi.exe")
        ]
        if any(os.path.exists(p) for p in paths):
            has_cuda = True
    else:
        try:
            subprocess.run(["nvidia-smi"], capture_output=True)
            has_cuda = True
        except Exception:
            pass
    return {"has_cuda": has_cuda}


def get_llama_url(hw):
    print("  🔍 Fetching latest llama.cpp release…")
    data = fetch_json(LLAMA_RELEASES_API)
    tag  = data["tag_name"]
    print(f"  Latest: {tag}")

    assets = data.get("assets", [])
    has_cuda = hw["has_cuda"]

    def score(name):
        """Higher = better match for our needs."""
        n = name.lower()
        if not (n.endswith(".zip") and "win" in n):
            return -1
        s = 0
        if "x64" in n or "amd64" in n: s += 10
        
        # Hardware preference
        if has_cuda:
            if "cuda" in n: s += 20
            if "cu12" in n: s += 5 # Prefer newer CUDA
        elif "vulkan" in n: s += 5 # Vulkan as secondary
            
        if "avx2" in n: s += 3
        if "noavx" in n: s -= 2
        return s

    scored = [(score(a["name"]), a) for a in assets if score(a["name"]) >= 0]
    if not scored:
        raise RuntimeError("No suitable Windows ZIP found in llama.cpp release.")

    scored.sort(key=lambda x: -x[0])
    best = scored[0][1]
    print(f"  Selected: {best['name']} (Optimization: {'CUDA' if has_cuda and 'cuda' in best['name'].lower() else 'CPU Portable'})")
    return best["browser_download_url"], best["name"]


def setup_llama(config):
    hw = detect_hardware()
    server_path = LLAMA_DIR / os.path.basename(config["llama_server_path"])
    
    # Check if we should skip
    existing_files = os.listdir(LLAMA_DIR) if LLAMA_DIR.exists() else []
    is_cpu_only = not any("cuda" in f.lower() or "vulkan" in f.lower() for f in existing_files if f.endswith(".exe") or f == "llama-server")
    
    if server_path.exists() and server_path.stat().st_size > 1_000_000:
        if hw["has_cuda"] and is_cpu_only:
            print("\n  ⚠️  Optimized GPU hardware detected, but current llama-server is CPU-only.")
            print("     Preparing to upgrade to optimized CUDA binary…")
        else:
            print(f"  ✅ llama-server found: {server_path}")
    else:
        print("\n  📥 Downloading llama-server…")
        TEMP_DIR.mkdir(exist_ok=True)

        url, fname = get_llama_url(hw)
        zip_path   = TEMP_DIR / fname
        download_file(url, zip_path, f"llama.cpp ({fname})")

        print("  📦 Extracting…")
        LLAMA_DIR.mkdir(exist_ok=True)

        with zipfile.ZipFile(zip_path, "r") as zf:
            for member in zf.namelist():
                base = os.path.basename(member)
                # #P3: Extract exe and all DLLs into llama-server/
                if base in ("llama-server.exe", "llama-server") or base.endswith(".dll"):
                    target = LLAMA_DIR / base
                    with zf.open(member) as src, open(target, "wb") as dst:
                        dst.write(src.read())
                    if base.endswith(".exe") or base == "llama-server":
                        print(f"  ✅ Extracted: {base}")

        shutil.rmtree(TEMP_DIR, ignore_errors=True)

    if server_path.exists():
        print(f"  ✅ llama-server ready: {server_path}")
    else:
        print("  ⚠️  llama-server.exe not found in ZIP.")
        print("     Try building from source: https://github.com/ggml-org/llama.cpp#build")


# ── Model ─────────────────────────────────────────────────

def setup_model(config):
    try:
        from huggingface_hub import hf_hub_download
    except ImportError:
        print("  ❌ huggingface_hub not installed — run: pip install huggingface_hub")
        sys.exit(1)

    MODELS_DIR.mkdir(exist_ok=True)
    repo   = config["hf_repo"]
    token  = os.environ.get("HF_TOKEN") or None

    model_name = config.get("model_filename") or config.get("model", "gemma-4-E4B-it-Q4_K_M.gguf")
    mmproj_name = config.get("mmproj_filename") or "mmproj-" + model_name.replace("-Q4_K_M.gguf", "-bf16.gguf")

    files = [
        (model_name,  MODELS_DIR / model_name),
        (mmproj_name, MODELS_DIR / mmproj_name),
    ]

    for fname, dest in files:
        # #P1: Skip if file > 100 MB (likely valid)
        if dest.exists() and dest.stat().st_size > 100_000_000:
            print(f"  ✅ {fname} already present ({dest.stat().st_size // (1024*1024)} MB)")
            continue

        print(f"\n  📥 Downloading {fname} from {repo}…")
        if fname.endswith(".gguf") and "Q4" in fname:
            print("     Large file (~3.5 GB) — this may take a while on slow connections.")

        downloaded = hf_hub_download(
            repo_id=repo,
            filename=fname,
            local_dir=str(MODELS_DIR),
            local_dir_use_symlinks=False,
            token=token,
        )
        print(f"  ✅ {fname} saved ({dest.stat().st_size // (1024*1024)} MB)")


# ── Main ──────────────────────────────────────────────────

def main():
    print_banner()
    config = load_config()

    print("─" * 40)
    print("Step 1/3: Python dependencies")
    print("─" * 40)
    ensure_deps()

    print("\n" + "─" * 40)
    print("Step 2/3: llama-server")
    print("─" * 40)
    try:
        setup_llama(config)
    except RuntimeError as e:
        print(f"\n  ❌ {e}")
        sys.exit(1)

    print("\n" + "─" * 40)
    print("Step 3/3: Gemma 4 model files")
    print("─" * 40)
    try:
        setup_model(config)
    except Exception as e:
        print(f"\n  ❌ Model download failed: {e}")
        print("  Tip: set HF_TOKEN env var if the model requires authentication.")
        sys.exit(1)

    print("\n" + "=" * 60)
    print("  ✅  Setup complete!")
    print("  Run start.bat (Windows) or:")
    print("  llama-server\\llama-server.exe -m models\\gemma-4-e4b-it-Q4_K_M.gguf ...")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    main()
