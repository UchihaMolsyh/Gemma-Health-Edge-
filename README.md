# 🏥 Gemma Health Edge

**A privacy-first AI health assistant that runs 100% on your own device.**
No cloud. No subscriptions. No one reading your health questions.

![Python](https://img.shields.io/badge/Python-3.10+-blue?style=flat-square&logo=python) ![Flutter](https://img.shields.io/badge/Flutter-3.7+-02569B?style=flat-square&logo=flutter) ![Model](https://img.shields.io/badge/Model-Gemma%204-orange?style=flat-square)

## 🎯 What is it? & Why

Every time someone Googles "chest pain" or types symptoms into ChatGPT, they are sending their most sensitive personal data to a corporation's servers. People in rural areas, low-income households, and developing nations have no access to quality medical information. Emergency rooms don't have AI triage yet. Cancer survivors can't get personalized post-treatment care.

**Gemma Health Edge is that assistant.**

It's a full-stack AI health platform powered by **Google's Gemma 4 AI models** running locally via llama.cpp (and ollama on pc web application) — a web dashboard you open in any browser, a native Flutter mobile app for iOS/Android, plus a safety layer that detects emergencies and blocks harmful outputs.

- 🌍 **Real-world impact** — works without internet, in clinics, rural areas, conflict zones
- 🔒 **Genuine privacy** — your PHI (Protected Health Information) never leaves your machine, (on local backends)
- 🚨 **Life-saving safety layer** — detects 100+ emergency patterns (cardiac arrest, overdose, suicide ideation) and responds with the correct emergency number for the user's country *before* the AI sees it
- 🧠 **Production-grade engineering** — dual-layer AI safety guardrails, circuit breakers, RLHF feedback collection, research augmentation from Wikipedia + PubMed — all in a hackathon project

> *"What if you had a brilliant medical friend in your pocket — one who never gossips, never sells your data, and works even with no Wi-Fi?"*

---

## 🏗️ The Validation — Tech Stack & Architecture

```
 ┌──────────────────────────────────┐   ┌────────────────────────────┐
 │       PC Web App (Browser)       │   │     Flutter Mobile App     │
 │  HTML + Vanilla CSS + JS         │   │  Android & iOS             │
 │  • Glassmorphism dark/light UI   │   │  • llama.cpp via Dart FFI  │
 │  • 10 languages (i18n)           │   │    (on-device LLM — no     │
 │  • Mood calendar + chat history  │   │     server!)               │
 │  • PDF export, RLHF thumbs       │   │  • Offline CSV RAG search  │
 │  • Camera + voice input          │   │  • TFLite on-device ML     │
 │  • Real-time GPU/TPS dashboard   │   │  • Encrypted Hive storage  │
 │  • Voice input + TTS             │   │  • Voice input + TTS       │
 └────────────────┬─────────────────┘   └──────────────┬────────────┘
                  │                                     │
                  │   HTTP REST + SSE Streaming         │
                  │   (Server-Sent Events: token stream)│
                  └─────────────────┬───────────────────┘
                                    │
                                    ▼
 ┌──────────────────────────────────────────────────────────────────┐
 │                  FastAPI MiddleMan Gateway  (port 8080)          │
 │                                                                  │
 │  Every request passes through this pipeline in order:           │
 │                                                                  │
 │  1. 🚨 Emergency Detector  ──→ if triggered: return crisis nums │
 │       (100+ regex patterns: cardiac, overdose, suicide, etc.)   │
 │                                                                  │
 │  2. 👋 Greeting Filter     ──→ if "hello/hi/hola": fast reply  │
 │       (40+ greetings across 15 languages, skips full LLM call)  │
 │                                                                  │
 │  3. 🔬 Research Engine     ──→ Wikipedia + PubMed + RAG engine   │
 │       in parallel (MD5-cached 2 hrs · only fires on medical       |
 |       keywords)                                                  │
 │                                                                  │
 │  4. 🩺 Clinical Profile    ──→ "Patient: Age 34, Diabetes..."  │
 │       (injected silently into every prompt from SQLite DB)      │
 │                                                                  │
 │  5. 🤖 LLM Call (streaming) ──→ routed to selected backend     │
 │                                                                  │
 │  6. 🛡️ Regex Critic        ──→ scans response for bad patterns │
 │       (anatomy errors, miracle cures, "stop meds" etc.)        │
 │                                                                  │
 │  7. 🧠 LLM Guardrail       ──→ Gemma 4 validates its response  │
 │       (circuit breaker: trips after 3 failures, resets 2 min)  │
 │                                                                  │
 │  8. 📊 RLHF Logging        ──→ thumbs up/down saved to votes   │
 │                                                                  │
 │  SQLite DB: chat_sessions · mood_entries · profiles (WAL mode) │
 └──────────────────────────────┬──────────────────────────────────┘
                                │  model backend selected by user:
              ┌─────────────────┼───────────────────┬──────────────┐
              ▼                 ▼                   ▼              ▼
   ┌─────────────────┐ ┌──────────────┐ ┌────────────────┐ ┌──────────┐
   │  llama.cpp      │ │    Ollama    │ │  Google AI     │ │OpenRouter│
   │  llama-server   │ │ port 11434   │ │  Studio API    │ │  API     │
   │  port 8081      │ │              │ │                │ │          │
   │  Gemma 4 E4B    │ │  gemma4 /    │ │ gemma-4-e4b   │ │google/   │
   │  Q4_K_M GGUF    │ │  gemma-4-9b  │ │ gemma-4-9b    │ │gemma-4   │
   │  5.3 GB model   │ │  local only  │ │ gemma-4-27b   │ │-27b      │
   │  32K context    │ │              │ │ cloud API     │ │cloud only│
   │  vision mmproj  │ │              │ │ your API key  │ │your key  │
   └─────────────────┘ └──────────────┘ └────────────────┘ └──────────┘
   ← DEFAULT, fully    ← if Ollama        ← fast cloud,      ← biggest
     offline, free       is installed       free tier avail    Gemma model
```

**Key technologies and why we chose them:**

| Layer | Tech | Reason |
|---|---|---|
| LLM Engine | llama.cpp + Gemma 4 Q4_K_M GGUF | Runs a 5.3 GB model on CPU — no GPU required |
| Backend | FastAPI + Uvicorn | Async Python, SSE streaming, automatic docs |
| Database | SQLite (WAL mode) | Zero config, embedded, works offline forever |
| PC Frontend | Vanilla HTML/CSS/JS | Zero build step — open in any browser |
| Mobile | Flutter + Dart FFI | One codebase, real native llama.cpp bindings |
| On-device RAG | Custom inverted index  | Offline CSV health knowledge base on phone and pc |
| On-device ML | TensorFlow Lite (LiteRT) | Lightweight symptom triage on mobile |
| Remote access | Cloudflare Tunnel | Free HTTPS link to your home AI from anywhere |

---

## 🎬 The Proof — Demo, Video & Core Features

> 🔗 **Live Demo Video:** [Coming soon]
> 📹 **Video Walkthrough:** [Link to demo video]
> 📦 **APK Download:** `build/app/outputs/flutter-apk/app-release.apk` (after `flutter build apk`)

### Feature 1 — Instant Emergency Response 🚨
Type "chest pain", "I want to kill myself", or "medical overdose" — the system **never sends these to the AI**. Instead, it instantly returns your local emergency number (911 / 999 / 112 / 000 / 119) with no latency.

### Feature 2 — Multimodal Vision + Voice 📸🎤
Upload a photo of a rash, pill bottle, or wound — Gemma 4's vision model describes what it sees. Or speak your symptoms out loud with voice input. Both work on the web app and the Flutter mobile app with offline processing.

### Feature 3 — Personalised Clinical Profile 🩺
Enter your allergies, conditions, and medications once. Every single AI prompt silently includes this context: *"Patient: Age 34, Conditions: Type 2 Diabetes, Medications: Metformin 500mg"* — making all responses contextual and safer.

### Feature 4 — Research-Grounded Answers 🔬
For medical questions, the system fetches real context from **Wikipedia** and **PubMed** in parallel, caches it, and injects it into the prompt — so Gemma 4's answers are grounded in actual medical literature.

---

## 🚀 The Run Guide — Get It Running in 60 Seconds

**You need:** Python 3.10+ installed. That's it.

```bash
# 1. Clone and enter the project
git clone <repo-url>
cd gemma-health-edge

# 2. Run automated setup
#    Downloads: llama-server binary + Gemma 4 model (~6.3 GB total)
#    Installs: all Python dependencies
python setup.py

# 3. Launch everything (Windows)
Launch_Gemma_Health.bat
#    Starts: Ollama (if installed) → llama-server (port 8081) → FastAPI (port 8080) → browser

# 3. OR launch from terminal (any OS)
python backend/main.py

# 4. Open in browser
#    http://127.0.0.1:8080
```

**First launch:** The 5.3 GB Gemma 4 model takes **30–60 seconds** to load into RAM. Subsequent launches are faster. The web app shows "Checking…" until the model is ready.

**Mobile app:**
```bash
cd frontend/phone/gemma_health_edge
flutter pub get
flutter run                          # on connected Android device
# OR: flutter build apk --release   # build APK to install manually
# In app Settings → set Server URL to http://<your-PC-IP>:8080
```

**Use Google AI Studio API or Openrouter API instead of local model** (no download required):
```bash
# In backend/config.json, set:
"require_local_model": false

# In the web app:
# Settings → Server → Google AI Studio/Openrouter → paste your API key
# Get a free key at: https://aistudio.google.com/app/apikey or https://openrouter.ai/keys
```

### 💻 Target Hardware Validation Profiles

To prove our local-first thesis, we empirically benchmarked the pipeline across three diverse consumer hardware configurations:

- **Profile A: The Office Workstation**  
  - *Hardware:* Intel Core i5-8500 (8th Gen) | 32GB DDR4 | Pure CPU (Windows 11)  
  - *Status:* 🟢 **Smooth.** Handling concurrent local gateway routing easily.
  - *Metrics:* Time-to-First-Token (TTFT): 0.5s–2.0s | Speed: 4–12+ tok/s | Full Gen: 12s–30s (Short), 1–3 min (Long)

- **Profile B: The Modern Thin-and-Light**  
  - *Hardware:* Intel Core Ultra 5 225U | 16GB RAM | Integrated Graphics (Windows 11)  
  - *Status:* 🟢 **Optimal.** Excellent performance utilizing modern architectural efficiencies.
  - *Metrics:* TTFT: 1.0s–2.0s | Speed: 15–30+ tok/s | Full Gen: 5s–10s (Short), 30s–60s (Long)

- **Profile C: The Legacy Laptop**  
  - *Hardware:* Intel Core i5-4210M | 12GB DDR3 | NVIDIA GeForce GTX 960M (Linux Mint XFCE)  
  - *Status:* 🟢 **Functional but kinda slow.** Proves that low-spec hardware over a decade old can offload mathematical execution.
  - *Metrics:* TTFT: 2.0s–4.0s | Speed: 1–11+ tok/s | Full Gen: 15s–45s (Short), 2–5 min (Long)

**Minimum Requirements:** Intel i5 6th Gen or Ryzen 3000 series CPU, 16GB RAM, 12GB free disk space. No dedicated GPU required.  
**Recommended Specification:** Intel i7 9th Gen or Ryzen 5000 series CPU, 24GB+ RAM, 20GB free space, ideally NVIDIA GPU (6GB+ VRAM).

---

## Credits & Acknowledgments

**Developer**  
- Molor Davaa — Solo developer for this project

**Special Thanks**  
- Google DeepMind & Unsloth community — For Gemma 4 AI model  
- Georgi Gerganov & the llama.cpp community
- Utsav Dey, Adil Shamim, and Palak Jain for their open datasets
- Real Drug Dataset & FINAL FOOD DATASET (Groups 1-5)

**License**  
This project is licensed under the [MIT License](LICENSE).

---

*"Making private, offline health information accessible to everyone."*

> ⚠️ **Disclaimers:** Gemma Health Edge provides health information only — not medical advice. Always consult a qualified healthcare professional. In emergencies, call local services immediately. This Phone and PC app has a API key powered variation and if you use API key powered variation, it'll be no longer 100% local and private. This AI model has low hallucination risk but never zero. Don't trust everything this AI model say. No matter what, consulting a qualified healthcare professional is better and trustworthy choice. 
