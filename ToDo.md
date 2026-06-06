# Project Roadmap & TODOs

This file tracks active development goals, known technical issues, and planned features for the **Gemma-Health-Edge** engine leading up to the **v3.0.0** milestone.

---

## 📅 Target: v3.0.0 (November-2026=>February-2027 Release)(The current version is v2.6.0)]

### 🛠️ Known Issues To Be Fixed

#### Frontend
- [ ] **Chat History Display Bug:** Fix the issue where the chat history occasionally requires a hard refresh to display correctly (Ctrl+Shift+R or Ctrl+F5).
- [ ] **Chat Scroll Jump:** Smooth out the scrolling mechanism to stop the chat window from jumping around during long conversations.
- [ ] **UI Polish:** Clean up and polish the interface layout in browser environments where the UI currently renders roughly.

#### Backend
- [ ] **Ollama Streaming Freeze:** Resolve the issue where the Ollama backend streaming occasionally freezes or cuts off mid-response on very long answers.
- [ ] **Session Database Corruption:** Fix edge cases where unexpected application crashes or quick shutdowns corrupt the local JSON/SQLite conversation history files.
- [ ] **KV Cache Initialization Failure:** Resolve intermittent initialization errors thrown when loading quantized weights without a pre-allocated key-value memory space.

#### Mobile App
- [ ] **Mobile App OOM & Loading Failures:** Eliminate fatal out-of-memory errors and model loading failures on older or low-RAM devices by adding proactive memory tracking loops.
- [ ] **LiteRT Engine Activation:** Stable Gemma weights are now landing; re-enable the currently disabled native LiteRT generative inference orchestration layer for direct, hardware-accelerated local execution.

#### Hardware / Performance & Research Engine
- [ ] **CPU-Only Time-To-First-Token (TTFT):** Optimize prompt processing to lower the 100–150 second TTFT delay seen on long prompts when running in CPU-only mode.
- [ ] **Low-Spec Optimization:** Implement optimization guardrails so low-spec devices (8GB RAM or older CPUs) run more efficiently than their current unoptimized baselines.
- [ ] **Research Engine Timeout Handling:** Refine the 20-second timeout handling for Wikipedia and PubMed online fetching so that falling back to local knowledge and offline RAG doesn't stall the pipeline.

---

### ➕ New Capabilities To Be Added
- [ ] **Abstract Base Engine Framework:** Rewrite the inference interface using a clean `BaseHealthEngine` abstraction layer to handle both desktop runtimes (Ollama, Llama.cpp) and mobile execution dynamically.
- [ ] **Hardware Fail-safe Monitors:** Build hardware system polling hooks to scale down context windows or generation depth when battery status is low or thermal throttling is triggered.
- [ ] **Inference-Level Prompt Injection Guardrails:** Secure the model pipeline by hardcoding medical warning injections directly into the backend constructor, ensuring strict constraints cannot be wiped out via text-based prompt manipulation.

---

### 📈 Optimization & Cleanliness Improvements
- [ ] **Quantization Optimization:** Transition the core deployment weights to highly optimized 4-bit and 8-bit quantization variants (GGUF/AWQ/LiteRT files) to drop active mobile memory consumption below 1 GB.
- [ ] **Sliding Window Context Allocation:** Move away from rough text-clipping approaches and implement a dedicated rolling context calculation window to maximize retention within fixed token constraints.
- [ ] **Application Configuration Decoupling:** Completely isolate application core files by moving hyper-parameters (such as generation temperature, context limits, and base paths) into an external, structured config loader (`.env` or `config.json`).

---

## 📋 Ongoing Maintenance & Testing
- [ ] Write integration test cases using `pytest` to validate core initialization protocols across changing environments.
- [ ] Set up formal GitHub template standards (`.github/ISSUE_TEMPLATE/`) to separate standard operational bug tracking from long-term feature requests.
- [ ] Update documentation files with updated local setup rules for mobile compilation environments once the LiteRT engine layers settle.
