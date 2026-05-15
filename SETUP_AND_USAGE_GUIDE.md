# Gemma Health Edge — Complete Setup & Usage Guide
**Date:** 2026-05-03  
**Version:** v2.1.0  
**Your PC Specs:** Intel Core i5-8500, Intel UHD Graphics 630, 16GB RAM

---

## 🖥️ PART 1: PC SETUP

### 1.1 System Requirements Verification

Your PC meets the **minimum requirements** ✅

| Component | Your Spec | Minimum | Status |
|-----------|-----------|---------|--------|
| **CPU** | Intel i5-8500 | Intel i5 | ✅ Good |
| **RAM** | 16 GB | 12 GB | ✅ Excellent |
| **GPU** | Intel UHD 630 | None (CPU works) | ✅ OK |
| **Storage** | Check free space | 12 GB free | ⚠️ Verify |
| **OS** | Windows 10/11 | Windows 10 | ✅ |

**Performance Expectation:** With Intel UHD 630 (integrated graphics), the AI will run on CPU. Expect **slower but usable** performance (~2-5 tokens/second).

---

### 1.2 Files Available on Your PC

| File | Status | Size | Purpose |
|------|--------|------|---------|
| `llama-server.exe` | ✅ Present | 16.7 MB | Local AI server |
| `gemma-4-E4B-it-Q4_K_M.gguf` | ✅ Present | 5.3 GB | AI model (Q4 quantized) |
| `mmproj-gemma-4-E4B-it-bf16.gguf` | ✅ Present | 991 MB | Vision/multimodal support |
| Python backend | ✅ Present | - | MiddleMan API gateway |

---

### 1.3 Step-by-Step PC Setup

#### Step 1: Install Python Dependencies

```powershell
cd C:\Users\uchih\combined\backend

# Check if pip is available
python --version  # Should show 3.10+

# Install all dependencies
pip install -r requirements.txt
```

**Expected packages installed:**
- fastapi, uvicorn (web server)
- httpx (HTTP client)
- pydantic (data validation)
- slowapi (rate limiting)
- cachetools (caching)
- pytest (testing)

#### Step 2: Start the Backend (Method A: Automatic)

```powershell
cd C:\Users\uchih\combined\backend
python main.py
```

This will:
1. Auto-detect hardware (Intel UHD 630 → CPU mode)
2. Start llama-server with optimal flags
3. Start MiddleMan on port 8000
4. Show status in console

**Expected output:**
```
🏥 Gemma Health Edge v2.1.0
[Hardware] Intel UHD Graphics 630 → Using CPU
[Model] Loading gemma-4-E4B-it-Q4_K_M.gguf...
[Server] llama-server started on port 8080
[MiddleMan] Starting on http://127.0.0.1:8000
✅ System ready!
```

#### Step 3: Open the Web Interface

**Option A — Direct file (simple):**
```
Double-click: C:\Users\uchih\combined\frontend\pc\index.html
```

**Option B — Through MiddleMan (recommended):**
```
Open browser: http://127.0.0.1:8000
```

This serves the frontend through the API gateway with proper CORS.

---

### 1.4 Alternative: Manual Backend Start

If `main.py` doesn't work, start components manually:

```powershell
# Terminal 1: Start llama-server
cd C:\Users\uchih\combined\backend\llama-server
.\llama-server.exe -m ..\models\gemma-4-E4B-it-Q4_K_M.gguf --port 8080 -c 4096

# Terminal 2: Start MiddleMan
cd C:\Users\uchih\combined\backend
python gateway.py
```

---

### 1.5 Verify Everything is Working

```powershell
# Test backend health
curl http://127.0.0.1:8000/api/v1/health

# Expected response:
{
  "status": "ok",
  "version": "2.1.0",
  "backends": {
    "local_llama": { "reachable": true },
    "ollama": { "reachable": false },
    "google": { "reachable": true }
  },
  "hardware": {
    "gpu": "Intel UHD Graphics 630",
    "vram": "N/A",
    "accel": "CPU"
  }
}
```

---

## 📱 PART 2: PHONE SETUP

### 2.1 Prerequisites

| Requirement | How to Check |
|-------------|--------------|
| Android phone | Settings → About Phone |
| WiFi connected to same network as PC | Settings → WiFi |
| Flutter app built | See section 2.3 |

### 2.2 Find Your PC's IP Address

```powershell
# On your PC, run:
ipconfig

# Look for "IPv4 Address" under your WiFi adapter
# Example: 192.168.1.100
```

### 2.3 Build the Phone App

```powershell
cd C:\Users\uchih\combined\frontend\phone\gemma_health_edge

# Check Flutter is installed
flutter --version

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release

# Or install directly to connected phone
flutter install
```

**APK location after build:**
```
build\app\outputs\flutter-apk\app-release.apk
```

Install this APK on your Android phone.

### 2.4 Configure Phone App

1. **Open the app**
2. **Tap Settings** (gear icon)
3. **Set Server URL:** `http://192.168.1.100:8000` (use your PC's IP)
4. **Select Mode:** `local` (or `google`/`openrouter` for cloud)
5. **Tap Save**
6. **Test connection** — should show green "Connected" status

### 2.5 Connection Methods

| Method | URL Format | When to Use |
|--------|-----------|-------------|
| **LAN Direct** | `http://192.168.1.XXX:8000` | Same WiFi network |
| **Cloudflare Tunnel** | `https://xyz.trycloudflare.com` | Remote access |
| **Localhost** | `http://127.0.0.1:8000` | Only on PC browser |

---

## 🎯 PART 3: HOW TO USE

### 3.1 First Launch (PC)

1. **Start backend:** `python backend/main.py`
2. **Open browser:** `http://127.0.0.1:8000`
3. **Read disclaimer** → Click "I Understand"
4. **See welcome screen** with 4 quick-action cards

### 3.2 Basic Chat Usage

| Action | How To Do It |
|--------|--------------|
| **Type message** | Click input box, type, press Enter |
| **Send** | Click arrow button or Enter |
| **New chat** | Click "+ New" in sidebar |
| **View history** | Click any chat in sidebar |
| **Delete chat** | Hover → click trash icon |

### 3.3 Every Feature Explained

#### 📝 Text Chat
- Type any health question
- AI responds with structured information
- **Disclaimer banner** always visible below input

#### 🖼️ Image Upload (Multimodal)
| Method | Steps |
|--------|-------|
| **Drag & Drop** | Drag image onto chat area |
| **Click upload** | Click 📎 icon → select file |
| **Paste** | Ctrl+V with image in clipboard |

**Supported formats:** JPEG, PNG, WebP
**Max size:** 8 MB

#### 📷 Camera Capture
1. Click 📷 icon in input bar
2. Allow camera permission
3. Click capture button
4. Image auto-attached to message

#### 🎤 Voice Input
1. Click 🎤 icon
2. Speak clearly
3. Click stop when done
4. Text appears in input box

#### 🔍 Research Mode
1. **Toggle on:** Click 🔍 in header or Settings → Features
2. **What it does:** Fetches Wikipedia + PubMed context for medical queries
3. **Indicator:** Shows "Research active" badge on responses

#### 📊 Clinical Profile
1. **Open Settings** → "My Clinical Profile"
2. **Fill in:** Age, weight, conditions, medications, allergies
3. **Benefit:** AI personalizes responses based on your health data
4. **Security:** Data encrypted with AES-GCM

#### 👍👎 RLHF Feedback
1. **After AI responds**, hover over message
2. **Click 👍** if helpful
3. **Click 👎** if incorrect → optionally type correction
4. **Purpose:** Improves future model fine-tuning

#### 💾 Export Chat
1. **Click download icon** in sidebar or message actions
2. **Format:** PDF or JSON
3. **Contains:** Full conversation with timestamps

#### 🌙 Theme Toggle
- **Click ☀️/🌙** in header to switch dark/light mode
- **Auto mode:** Follows system preference

#### 🌍 Language
- **Settings** → Language → select from 15+ languages
- UI and AI responses translate automatically

### 3.4 Backend Modes (How to Switch)

1. **Open Settings** (gear icon)
2. **Select Server Tab**
3. **Choose backend:**

| Mode | Use When | Requirements |
|------|----------|--------------|
| **🏠 Local PC** | Default, always works | llama-server running |
| **🚀 Sub-Backend** | Testing E2B sandbox | E2B configured |
| **🦙 Ollama** | Using Ollama install | Ollama on port 11434 |
| **☁️ Google AI** | Need cloud power | API key from Google AI Studio |
| **☁️ OpenRouter** | Access many models | API key from OpenRouter |

**Auto-Detect button:** Tests all backends and picks best available.

### 3.5 Emergency Features

| Trigger | Response |
|---------|----------|
| Type "chest pain" | Shows emergency card with 911/local emergency number |
| Type "suicide" | Shows crisis hotline numbers |
| Type "overdose" | Shows poison control |

**Safety:** AI still provides information, but emergency info appears FIRST.

### 3.6 Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Enter` | Send message |
| `Shift + Enter` | New line in input |
| `Ctrl + N` | New chat |
| `Ctrl + F` | Search messages |
| `Esc` | Close modals |

---

## 🔒 PART 4: SAFETY & PRIVACY

### 4.1 Security Features Active

| Feature | How It Protects You |
|---------|---------------------|
| **PHI Encryption** | Your health data encrypted with AES-GCM |
| **No API Key Storage** | Keys never saved to disk |
| **30-Min Timeout** | Auto-clears PHI after inactivity |
| **Tab Close Cleanup** | PHI wiped when you close browser |
| **XSS Protection** | AI responses sanitized before display |
| **CSP Headers** | Blocks malicious scripts |

### 4.2 Data Privacy

| Data | Stored Where | Encrypted |
|------|--------------|-----------|
| Chat messages | Browser localStorage | ✅ Yes |
| Clinical profile | Browser localStorage | ✅ Yes |
| API keys | Session only | ✅ Never persisted |
| Images | Temporary (session) | ✅ Deleted after send |

### 4.3 What NEVER Happens

- ❌ Data sent to cloud (unless you choose Google/OpenRouter mode)
- ❌ Chat history saved to server
- ❌ Personal info shared with third parties
- ❌ AI makes diagnoses or prescribes

---

## 🔧 PART 5: TROUBLESHOOTING

### 5.1 "AI Connection Error"

| Cause | Fix |
|-------|-----|
| Backend not running | `python backend/main.py` |
| Wrong port | Check `config.json` → port 8000 |
| Firewall blocking | Add exception for Python |
| Browser CORS | Use `http://127.0.0.1:8000` not `file://` |

### 5.2 "Model Loading Slowly"

| Your Hardware | Expected Load Time |
|---------------|-------------------|
| Intel UHD 630 (CPU) | 30-60 seconds |
| Dedicated GPU | 5-15 seconds |

**Fix:** Wait, or use smaller model (if available)

### 5.3 Phone Won't Connect

| Check | Command |
|-------|---------|
| Same network? | PC: `ipconfig`, Phone: WiFi settings |
| Port open? | PC: `netstat -an \| findstr 8000` |
| Firewall? | Temporarily disable Windows Firewall |
| URL correct? | Must be `http://` not `https://` for LAN |

### 5.4 Get Logs for Support

```powershell
# Backend logs
cd C:\Users\uchih\combined\backend
python main.py > backend.log 2>&1

# Browser logs
# Press F12 → Console → Save as...
```

---

## 📋 PART 6: FEATURE CHECKLIST

### Core Features
- [ ] Start backend with `python main.py`
- [ ] Open web interface at `http://127.0.0.1:8000`
- [ ] Accept disclaimer
- [ ] Send text message
- [ ] Receive AI response
- [ ] Start new chat
- [ ] View chat history in sidebar

### Advanced Features
- [ ] Upload image (drag & drop)
- [ ] Capture from camera
- [ ] Use voice input
- [ ] Enable research mode
- [ ] Fill clinical profile
- [ ] Give RLHF feedback (👍/👎)
- [ ] Export chat as PDF
- [ ] Change theme (dark/light)
- [ ] Change language

### Backend Features
- [ ] Switch backend modes (local/ollama/google)
- [ ] Auto-detect best backend
- [ ] Check health endpoint
- [ ] Start Cloudflare tunnel
- [ ] Sync session to phone

### Phone Features
- [ ] Build and install APK
- [ ] Connect to PC backend
- [ ] Send message from phone
- [ ] Receive response on phone
- [ ] Cross-device sync

---

## 🚀 QUICK START COMMANDS

### Daily Use (PC)
```powershell
# 1. Start backend
cd C:\Users\uchih\combined\backend
python main.py

# 2. Open browser (in new window)
start http://127.0.0.1:8000

# 3. When done, press Ctrl+C in terminal to stop
```

### Phone Testing
```powershell
# 1. Get PC IP
ipconfig | findstr "IPv4"

# 2. In phone app, set URL to:
# http://192.168.1.XXX:8000 (replace XXX with your IP)
```

---

**End of Setup & Usage Guide**

For issues, check:
- `CONNECTION_ERROR_FIXES.md` — Connection troubleshooting
- `MEDICAL_AUDIT_REPORT.md` — Security details
- `SYSTEM_VERIFICATION_REPORT.md` — Complete system status
