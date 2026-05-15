
 * Gemma Health Edge — Main Application
 * 
 * Orchestrates the user interface, chat lifecycle, and diagnostic dashboard.
 * Designed for privacy-first, offline-ready clinical assistance.
 */

(function (window) {
  'use strict';
  
  const GHE = window.GHE || {}; 
  window.GHE = GHE;

  // ── State Management ───────────────────────────────────────────────────────
  
  const state = {
    currentSession:     null,
    messages:           [],
    isGenerating:       false,
    abortController:    null,
    lang:               'en',
    theme:              'dark',
    sidebarCollapsed:   false,
    rightSectorOpen:    false,
    imageAttachment:    null,
    isRecording:        false,
    disclaimerAccepted: false,
    showThinking:       true,
    visionSupported:    true
  };
  GHE.State = state;

  // ── Selectors & Helpers ────────────────────────────────────────────────────

  const $  = (id) => document.getElementById(id);
  const on = (el, evt, fn) => el?.addEventListener(evt, fn);
  const t  = (key) => GHE.Core.t(key, state.lang);

  const icons = {
    copy:    '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>',
    delete:  '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>',
    refresh: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M23 4v6h-6"/><path d="M1 20v-6h6"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>',
    close:   '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M18 6L6 18M6 6l12 12"/></svg>',
  };

  // ── DOM Cache ──────────────────────────────────────────────────────────────

  const els = {};
  const cacheElements = () => {
    const ids = [
      'disclaimer-modal', 'settings-modal', 'camera-modal', 'search-modal',
      'sidebar', 'messages-container', 'welcome-screen', 'message-input',
      'btn-send', 'btn-sidebar-new', 'connection-status', 'right-sector',
      'hw-gpu', 'hw-vram', 'hw-accel', 'session-title', 'btn-settings',
      'clinical-allergies', 'clinical-conditions', 'clinical-medications',
      'clinical-age', 'clinical-weight', 'clinical-notes', 'btn-save-clinical'
    ];
    ids.forEach(id => {
      const key = id.replace(/-([a-z])/g, (_, l) => l.toUpperCase());
      els[key] = $(id);
    });
  };

  // ── UI Actions ─────────────────────────────────────────────────────────────

  const openModal  = (m) => m?.classList.add('active');
  const closeModal = (m) => m?.classList.remove('active');

  const updateStatus = async () => {
    const health = await fetch(`${GHE.Core.getAPIBase()}/api/v1/health`).then(r => r.json()).catch(() => null);
    const online = !!health;

    state.visionSupported = health ? health.vision_supported !== false : true;

    // Sidebar indicator
    const dot = els.connectionStatus;
    if (dot) {
      dot.className = `connection-status ${online ? 'connected' : 'disconnected'}`;
      dot.querySelector('.status-text').textContent = online ? 'Connected' : 'Offline';
    }

    // Settings panel indicator
    const srv = $('server-status');
    if (srv) {
      srv.innerHTML = `<span class="status-dot ${online ? 'online' : 'offline'}"></span><span>${online ? 'Online' : 'Offline'}</span>`;
    }
  };

  const thinkingEl = () => document.getElementById('thinking-indicator');

  const thinkingIndicator = (show) => {
    let el = thinkingEl();
    if (show && !el) {
      el = document.createElement('div');
      el.id = 'thinking-indicator';
      el.className = 'message-wrapper assistant';
      el.innerHTML = '<div class="message assistant"><div class="message-content" style="color:var(--text-tertiary);font-style:italic;display:flex;align-items:center;gap:8px"><span class="thinking-dots"><span>.</span><span>.</span><span>.</span></span> Thinking</div></div>';
      els.messagesContainer.appendChild(el);
      els.messagesContainer.scrollTo({ top: els.messagesContainer.scrollHeight, behavior: 'smooth' });
    } else if (!show && el) {
      el.remove();
    }
  };

  const renderMessage = (msg) => {
    thinkingIndicator(false);
    const wrap = document.createElement('div');
    wrap.className = `message-wrapper ${msg.role}`;
    wrap.innerHTML = `
      <div class="message ${msg.role}">
        <div class="message-content">${GHE.Core.formatMarkdown(msg.content)}</div>
        <div class="message-actions">
          <button class="btn-action" title="Copy" onclick="GHE.App.copyMessage('${msg.id}')">${icons.copy}</button>
          <button class="btn-action" title="Delete" onclick="GHE.App.deleteMessage('${msg.id}')">${icons.delete}</button>
        </div>
      </div>
    `;
    els.messagesContainer.appendChild(wrap);
    els.messagesContainer.scrollTo({ top: els.messagesContainer.scrollHeight, behavior: 'smooth' });
  };

  // ── Session Management ─────────────────────────────────────────────────────

  const loadSession = async (id) => {
    const session = await GHE.Core.ChatStorage.getSession(id);
    if (!session) return;
    
    state.currentSession = session;
    state.messages = session.messages || [];
    els.messagesContainer.innerHTML = '';
    els.welcomeScreen.hidden = true;
    els.sessionTitle.textContent = session.title || 'Conversation';
    state.messages.forEach(renderMessage);
  };

  const createNewSession = () => {
    if (state.isGenerating) {
      GHE.Core.showToast('Please wait for the response to finish.', 'info');
      return;
    }
    state.currentSession = null;
    state.messages = [];
    els.messagesContainer.innerHTML = '';
    els.welcomeScreen.hidden = false;
    els.sessionTitle.textContent = 'Gemma Health Edge';
  };

  // ── Chat Flow ──────────────────────────────────────────────────────────────

  const sendMessage = async () => {
    const text = els.messageInput.value.trim();
    if (!text || state.isGenerating) return;

    if (!state.currentSession) {
      state.currentSession = { id: GHE.Core.generateId(), title: text.substring(0, 30) + '...', messages: [] };
    }

    els.messageInput.value = '';
    els.welcomeScreen.hidden = true;

    const userMsg = { id: GHE.Core.generateId(), role: 'user', content: text };
    state.messages.push(userMsg);
    renderMessage(userMsg);

    state.isGenerating = true;
    els.btnSend.disabled = true;
    els.btnSend.classList.add('generating');
    thinkingIndicator(true);

    try {
      const mode = GHE.Core.Config.get('apiMode');
      const apiKey = mode === 'google' ? GHE.Core.Storage.get('gemma-api-key', '')
                   : mode === 'openrouter' ? GHE.Core.Storage.get('openrouter-api-key', '')
                   : '';
      const resp = await fetch(`${GHE.Core.getAPIBase()}/api/v1/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          messages: state.messages,
          mode:     mode,
          research: GHE.Core.Config.get('researchMode'),
          api_key:  apiKey,
        })
      });

      if (!resp.ok) {
        const errBody = await resp.text().catch(() => '');
        throw new Error(errBody ? `${resp.status}: ${errBody.substring(0, 200)}` : `HTTP ${resp.status}`);
      }

      const data = await resp.json();
      const assistantMsg = { id: GHE.Core.generateId(), role: 'assistant', content: data.content };
      state.messages.push(assistantMsg);
      renderMessage(assistantMsg);

      const st = $('stat-ttft'); if (st && data.ttft_ms) st.textContent = data.ttft_ms > 0 ? `${data.ttft_ms.toFixed(0)}ms` : '-';
      const st2 = $('stat-tps'); if (st2 && data.tps) st2.textContent = data.tps > 0 ? `${data.tps.toFixed(1)} t/s` : '-';
      const st3 = $('stat-time'); if (st3 && data.total_time_ms) st3.textContent = data.total_time_ms > 0 ? `${(data.total_time_ms / 1000).toFixed(1)}s` : '-';
      
      state.currentSession.messages = state.messages;
      await GHE.Core.ChatStorage.saveSession(state.currentSession);
    } catch (e) {
      GHE.Core.showToast(e.message?.includes('503') ? 'Server busy — model still loading. Retry in a few seconds.' : e.message || 'Failed to get response.', 'error');
    } finally {
      state.isGenerating = false;
      els.btnSend.disabled = false;
      els.btnSend.classList.remove('generating');
    }
  };

  // ── Settings & Clinical Profile ───────────────────────────────────────────

  const loadClinicalProfile = async () => {
    const p = await GHE.Core.ClinicalProfile.get();
    if (els.clinicalAllergies)   els.clinicalAllergies.value   = p.allergies || '';
    if (els.clinicalConditions)  els.clinicalConditions.value  = p.conditions || '';
    if (els.clinicalMedications) els.clinicalMedications.value = p.medications || '';
    if (els.clinicalAge)         els.clinicalAge.value         = p.age || '';
    if (els.clinicalWeight)      els.clinicalWeight.value      = p.weight || '';
    if (els.clinicalNotes)       els.clinicalNotes.value       = p.notes || '';
  };

  const saveClinicalProfile = async () => {
    const data = {
      allergies:   els.clinicalAllergies.value,
      conditions:  els.clinicalConditions.value,
      medications: els.clinicalMedications.value,
      age:         els.clinicalAge.value,
      weight:      els.clinicalWeight.value,
      notes:       els.clinicalNotes.value
    };
    const ok = await GHE.Core.ClinicalProfile.save(data);
    if (ok) GHE.Core.showToast('Clinical profile saved locally.', 'success');
  };

  // ── Settings Tab Navigation ───────────────────────────────────────────────

  const switchSettingsTab = (tabId) => {
    document.querySelectorAll('.settings-nav-item').forEach(b => {
      b.classList.remove('active');
      b.setAttribute('aria-selected', 'false');
    });
    document.querySelectorAll('.settings-panel').forEach(p => {
      p.classList.remove('active');
      p.hidden = true;
    });
    const tabBtn = document.querySelector(`.settings-nav-item[data-tab="${tabId}"]`);
    if (tabBtn) { tabBtn.classList.add('active'); tabBtn.setAttribute('aria-selected', 'true'); }
    const panel = $(`tab-${tabId}`);
    if (panel) { panel.classList.add('active'); panel.hidden = false; }
  };

  // ── File / Image Upload ──────────────────────────────────────────────────

  const handleFileUpload = () => {
    if (!state.visionSupported) {
      GHE.Core.showToast('Cannot read image input (this model does not support image input).', 'error');
      return;
    }
    const input = $('file-input');
    if (!input) return;
    input.click();
  };

  const onFileSelected = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!state.visionSupported) {
      GHE.Core.showToast(`Cannot read "${file.name}" (this model does not support image input).`, 'error');
      return;
    }
    const preview = $('image-preview');
    const img = $('preview-img');
    if (preview && img) {
      preview.hidden = false;
      img.src = URL.createObjectURL(file);
    }
    state.imageAttachment = await GHE.Core.resizeImage(file);
  };

  // ── Camera ────────────────────────────────────────────────────────────────

  let cameraStream = null;

  const openCamera = async () => {
    if (!state.visionSupported) {
      GHE.Core.showToast('Cannot read image input (this model does not support image input).', 'error');
      return;
    }
    const modal = $('camera-modal');
    const video = $('camera-video');
    if (!modal || !video) return;
    try {
      cameraStream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
      video.srcObject = cameraStream;
      openModal(modal);
    } catch (e) {
      GHE.Core.showToast('Camera access denied or unavailable.', 'error');
    }
  };

  const closeCamera = () => {
    if (cameraStream) { cameraStream.getTracks().forEach(t => t.stop()); cameraStream = null; }
    closeModal($('camera-modal'));
  };

  const capturePhoto = () => {
    if (!state.visionSupported) {
      GHE.Core.showToast('Cannot read image input (this model does not support image input).', 'error');
      return;
    }
    const video = $('camera-video');
    const canvas = $('camera-canvas');
    const preview = $('image-preview');
    const img = $('preview-img');
    if (!video || !canvas || !preview || !img) return;
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    canvas.getContext('2d').drawImage(video, 0, 0);
    const dataUrl = canvas.toDataURL('image/jpeg', 0.85);
    state.imageAttachment = dataUrl;
    preview.hidden = false;
    img.src = dataUrl;
    closeCamera();
  };

  const switchCamera = async () => {
    if (!cameraStream) return;
    const facing = cameraStream.getVideoTracks()[0]?.getSettings().facingMode;
    const newFacing = facing === 'environment' ? 'user' : 'environment';
    cameraStream.getTracks().forEach(t => t.stop());
    try {
      cameraStream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: newFacing } });
      const video = $('camera-video');
      if (video) video.srcObject = cameraStream;
    } catch (e) {
      GHE.Core.showToast('Failed to switch camera.', 'error');
    }
  };

  // ── Voice Input ──────────────────────────────────────────────────────────

  let voiceRecognition = null;

  const toggleVoice = () => {
    if (state.isRecording) {
      if (voiceRecognition) { voiceRecognition.stop(); voiceRecognition = null; }
      state.isRecording = false;
      const btn = $('btn-voice');
      if (btn) btn.innerHTML = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 1a3 3 0 00-3 3v8a3 3 0 006 0V4a3 3 0 00-3-3z"/><path d="M19 10v2a7 7 0 01-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/></svg>';
      return;
    }
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      GHE.Core.showToast('Voice input not supported in this browser.', 'error');
      return;
    }
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    voiceRecognition = new SpeechRecognition();
    voiceRecognition.lang = state.lang;
    voiceRecognition.continuous = false;
    voiceRecognition.interimResults = false;
    voiceRecognition.onresult = (e) => {
      const transcript = e.results[0][0].transcript;
      els.messageInput.value += transcript;
      state.isRecording = false;
      const btn = $('btn-voice');
      if (btn) btn.innerHTML = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 1a3 3 0 00-3 3v8a3 3 0 006 0V4a3 3 0 00-3-3z"/><path d="M19 10v2a7 7 0 01-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/></svg>';
    };
    voiceRecognition.onerror = () => {
      state.isRecording = false;
      GHE.Core.showToast('Voice recognition error.', 'error');
      const btn = $('btn-voice');
      if (btn) btn.innerHTML = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 1a3 3 0 00-3 3v8a3 3 0 006 0V4a3 3 0 00-3-3z"/><path d="M19 10v2a7 7 0 01-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/></svg>';
    };
    voiceRecognition.start();
    state.isRecording = true;
    const btn = $('btn-voice');
    if (btn) btn.innerHTML = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2"><rect x="6" y="3" width="4" height="18" rx="1"/><rect x="14" y="3" width="4" height="18" rx="1"/></svg>';
  };

  // ── Export Chat ──────────────────────────────────────────────────────────

  const exportChat = () => {
    if (state.messages.length === 0) {
      GHE.Core.showToast('No messages to export.', 'info');
      return;
    }
    const lines = state.messages.map(m => `[${m.role.toUpperCase()}]\n${m.content}`).join('\n---\n');
    const blob = new Blob([lines], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `gemma-health-chat-${Date.now()}.txt`;
    a.click();
    URL.revokeObjectURL(url);
    GHE.Core.showToast('Chat exported.', 'success');
  };

  // ── Clear Chat ──────────────────────────────────────────────────────────

  const clearChat = () => {
    if (state.isGenerating) {
      GHE.Core.showToast('Please wait for the response to finish.', 'info');
      return;
    }
    if (state.messages.length === 0) return;
    state.messages = [];
    els.messagesContainer.innerHTML = '';
    els.welcomeScreen.hidden = false;
  };

  // ── Search Sessions ─────────────────────────────────────────────────────

  const openSearch = () => {
    openModal($('search-modal'));
    const input = $('search-input');
    if (input) { input.value = ''; input.focus(); }
    const results = $('search-results');
    if (results) results.innerHTML = '<div class="search-hint" style="padding:1rem;color:var(--text-tertiary);font-size:0.85rem">Type to search your conversations...</div>';
  };

  const performSearch = async (query) => {
    const results = $('search-results');
    if (!results) return;
    if (!query.trim()) {
      results.innerHTML = '<div class="search-hint" style="padding:1rem;color:var(--text-tertiary);font-size:0.85rem">Type to search your conversations...</div>';
      return;
    }
    results.innerHTML = '<div style="padding:1rem;color:var(--text-tertiary)">Searching...</div>';
    const sessions = await GHE.Core.ChatStorage.getSessions();
    const matched = sessions.filter(s => 
      s.title?.toLowerCase().includes(query.toLowerCase()) ||
      s.messages?.some(m => m.content?.toLowerCase().includes(query.toLowerCase()))
    );
    if (matched.length === 0) {
      results.innerHTML = '<div style="padding:1rem;color:var(--text-tertiary)">No results found.</div>';
      return;
    }
    results.innerHTML = matched.map(s => `
      <div class="search-result-item" data-session-id="${s.id}" style="padding:0.6rem 0.8rem;cursor:pointer;border-bottom:1px solid var(--border-color);display:flex;align-items:center;gap:0.6rem">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>
        <div><div style="font-weight:500;font-size:0.85rem">${GHE.Core.sanitizeHTML(s.title || 'Untitled')}</div><div style="font-size:0.7rem;color:var(--text-tertiary)">${s.messages?.length || 0} messages</div></div>
      </div>
    `).join('');
    results.querySelectorAll('.search-result-item').forEach(el => {
      el.addEventListener('click', () => {
        loadSession(el.dataset.sessionId);
        closeModal($('search-modal'));
      });
    });
  };

  // ── Mood Tracker ──────────────────────────────────────────────────────────

  let selectedMood = 0;

  const saveMood = async () => {
    if (selectedMood === 0) { GHE.Core.showToast('Select a mood first.', 'info'); return; }
    const note = $('mood-note-input')?.value || '';
    const today = new Date().toISOString().split('T')[0];
    const ok = await GHE.Core.MoodTracker.saveMood(today, selectedMood, note);
    if (ok) {
      GHE.Core.showToast('Mood saved!', 'success');
      if ($('mood-note-input')) $('mood-note-input').value = '';
      selectedMood = 0;
      document.querySelectorAll('.mood-btn').forEach(b => b.classList.remove('selected'));
    }
  };

  // ── Auto-detect Server ───────────────────────────────────────────────────

  const autoDetect = async () => {
    const statusEl = $('server-status');
    if (statusEl) {
      statusEl.innerHTML = '<span class="status-dot checking"></span><span>Scanning...</span>';
    }
    const urls = ['http://127.0.0.1:8080', 'http://127.0.0.1:11434', 'http://localhost:8080', 'http://localhost:11434'];
    for (const url of urls) {
      try {
        const resp = await fetch(`${url}/api/v1/health`, { signal: AbortSignal.timeout(2000) });
        if (resp.ok) {
          GHE.Core.Config.set('middlemanUrl', url);
          if (statusEl) statusEl.innerHTML = `<span class="status-dot online"></span><span>Found: ${url}</span>`;
          updateStatus();
          return;
        }
      } catch (e) { continue; }
    }
    if (statusEl) statusEl.innerHTML = '<span class="status-dot offline"></span><span>No server found</span>';
    GHE.Core.showToast('Could not auto-detect a running server.', 'error');
  };

  // ── Troubleshooting ─────────────────────────────────────────────────────

  const testBackend = async () => {
    GHE.Core.showToast('Testing backend connection...', 'info');
    await updateStatus();
    const cs = $('connection-status');
    if (cs?.classList.contains('connected')) GHE.Core.showToast('Backend is reachable.', 'success');
    else GHE.Core.showToast('Backend unreachable. Check your server.', 'error');
  };

  const clearAppCache = async () => {
    if ('caches' in window) {
      const keys = await caches.keys();
      await Promise.all(keys.map(k => caches.delete(k)));
    }
    localStorage.clear();
    GHE.Core.showToast('Cache and local storage cleared. Reloading...', 'success');
    setTimeout(() => location.reload(), 1000);
  };

  const resetAllSettings = () => {
    GHE.Core.Config.reset();
    GHE.Core.showToast('Settings reset. Reloading...', 'success');
    setTimeout(() => location.reload(), 1000);
  };

  // ── Reconnect ────────────────────────────────────────────────────────────

  const reconnect = async () => {
    const btn = $('btn-reconnect');
    if (btn) { btn.disabled = true; btn.innerHTML = '<span>Connecting...</span>'; }
    await updateStatus();
    if (btn) { btn.disabled = false; btn.style.display = 'none'; }
  };

  // ── Right Sector Toggle ─────────────────────────────────────────────────

  const toggleRightSector = () => {
    state.rightSectorOpen = !state.rightSectorOpen;
    const sector = $('right-sector');
    if (sector) sector.classList.toggle('collapsed', !state.rightSectorOpen);
  };

  const closeRightSector = () => {
    state.rightSectorOpen = false;
    const sector = $('right-sector');
    if (sector) sector.classList.add('collapsed');
  };

  // ── Help Modal ──────────────────────────────────────────────────────────

  const openHelp = () => openModal($('help-modal'));
  const closeHelp = () => closeModal($('help-modal'));

  // ── Initialization ─────────────────────────────────────────────────────────

  const init = () => {
    console.log('[App] init() started');
    // Phase 1: Register all event handlers FIRST (never skipped by errors)
    registerEventHandlers();

    // Phase 2: Setup UI state from saved config
    try {
      cacheElements();
      restoreSettingsUI();
      updateStatus();
      loadClinicalProfile();
      applyLanguage(state.lang);
      renderCalendar();

      // Hardware Diagnostics - prefer backend health data over WebGPU
      fetch(`${GHE.Core.getAPIBase()}/api/v1/health`).then(r => r.json()).then(h => {
        if (els.hwGpu) els.hwGpu.textContent = h.gpu || 'Unknown';
        if (els.hwVram) els.hwVram.textContent = h.vram_gb ? `${h.vram_gb} GB` : 'N/A';
        if (els.hwAccel) els.hwAccel.textContent = h.accelerator || 'CPU';
      }).catch(() => {
        if (GHE.Core) GHE.Core.detectGPU().then(hw => {
          if (els.hwGpu) els.hwGpu.textContent = hw.gpu;
          if (els.hwVram) els.hwVram.textContent = hw.vram;
          if (els.hwAccel) els.hwAccel.textContent = hw.accel;
        }).catch(() => {});
      });

      // Disclaimer
      if (!localStorage.getItem('ghe_disclaimer_accepted')) {
        const dm = $('disclaimer-modal');
        if (dm) dm.classList.add('active');
      }

      // Periodic checks
      setInterval(updateStatus, 30000);
    } catch (e) { console.error('[App] init setup error:', e); }
  };

  // ── Calendar Render ────────────────────────────────────────────────────────

  const renderCalendar = () => {
    const container = $('calendar-body');
    if (!container) return;
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const firstDay = new Date(year, month, 1).getDay();
    const today = now.getDate();

    let html = '<table class="cal-table" style="width:100%;border-collapse:collapse;font-size:0.72rem"><thead><tr>';
    ['Su','Mo','Tu','We','Th','Fr','Sa'].forEach(d => { html += `<th style="padding:2px;text-align:center;color:var(--text-tertiary)">${d}</th>`; });
    html += '</tr></thead><tbody><tr>';
    for (let i = 0; i < firstDay; i++) html += '<td style="padding:2px"></td>';
    for (let day = 1; day <= daysInMonth; day++) {
      const isToday = day === today ? ' style="background:var(--accent-1);color:#fff;border-radius:50%;font-weight:700"' : ' style="color:var(--text-primary)"';
      html += `<td align="center" style="padding:2px"><span${isToday}>${day}</span></td>`;
      if ((firstDay + day) % 7 === 0 && day < daysInMonth) html += '</tr><tr>';
    }
    html += '</tr></tbody></table>';
    container.innerHTML = html;

    // Update count
    const countEl = $('cal-count');
    if (countEl) countEl.textContent = 'Today: ' + today;
  };

  // ── Event Handlers (always registered, never skipped) ──────────────────────

  const registerEventHandlers = () => {
    console.log('[App] Registering event handlers...');
    try {
    const CHAT = 'click';
    // ── Chat
    on($('btn-send'), CHAT, sendMessage);
    on($('message-input'), 'keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
    });

    // ── Sidebar
    on($('btn-sidebar-new'), CHAT, createNewSession);
    on($('btn-sidebar-search'), CHAT, openSearch);
    on($('btn-sidebar-clear'), CHAT, clearChat);
    on($('btn-sidebar-export'), CHAT, exportChat);
    on($('btn-help'), CHAT, openHelp);
    on($('btn-settings'), CHAT, () => { const m=$('settings-modal'); if(m)m.classList.add('active'); });
    on($('btn-sidebar-expand'), CHAT, () => { const s=$('sidebar'); if(s)s.classList.remove('collapsed'); });
    on($('btn-sidebar-collapse'), CHAT, () => { const s=$('sidebar'); if(s)s.classList.add('collapsed'); });

    // ── Settings modal
    on($('settings-close'), CHAT, () => { const m=$('settings-modal'); if(m)m.classList.remove('active'); });
    on($('settings-overlay'), CHAT, () => { const m=$('settings-modal'); if(m)m.classList.remove('active'); });

    // Settings tab nav
    document.querySelectorAll('.settings-nav-item').forEach(b => {
      on(b, CHAT, () => {
        document.querySelectorAll('.settings-nav-item').forEach(x => { x.classList.remove('active'); x.setAttribute('aria-selected','false'); });
        document.querySelectorAll('.settings-panel').forEach(p => { p.classList.remove('active'); p.hidden = true; });
        b.classList.add('active'); b.setAttribute('aria-selected','true');
        const p = $(`tab-${b.dataset.tab}`);
        if (p) { p.classList.add('active'); p.hidden = false; }
      });
    });

    // ── Theme
    document.querySelectorAll('.theme-btn').forEach(b => {
      on(b, CHAT, () => {
        document.querySelectorAll('.theme-btn').forEach(x => x.classList.remove('active'));
        b.classList.add('active');
        document.documentElement.setAttribute('data-theme', b.dataset.theme);
        if (GHE.Core) GHE.Core.Config.set('theme', b.dataset.theme);
      });
    });

    // ── Language
    document.querySelectorAll('.lang-btn').forEach(b => {
      on(b, CHAT, () => {
        document.querySelectorAll('.lang-btn').forEach(x => x.classList.remove('active'));
        b.classList.add('active');
        state.lang = b.dataset.lang;
        if (GHE.Core) GHE.Core.Config.set('lang', b.dataset.lang);
        applyLanguage(b.dataset.lang);
      });
    });

    // ── Feature toggles
    on($('toggle-research'), 'change', (e) => { if(GHE.Core)GHE.Core.Config.set('researchMode',e.target.checked); });
    on($('toggle-thinking'), 'change', (e) => { if(GHE.Core)GHE.Core.Config.set('showThinking',e.target.checked); state.showThinking=e.target.checked; });
    on($('toggle-camera'), 'change', (e) => {
      if(GHE.Core)GHE.Core.Config.set('cameraEnabled',e.target.checked);
      const cb=$('btn-camera'); if(cb)cb.style.display=e.target.checked?'':'none';
    });
    on($('toggle-voice'), 'change', (e) => { if(GHE.Core)GHE.Core.Config.set('voiceEnabled',e.target.checked); });

    // ── API mode
    on($('api-mode-select'), 'change', (e) => {
      const v=e.target.value;
      ['gemma-api-key-group','openrouter-api-key-group'].forEach(id=>{
        const el=$(id); if(el)el.style.display=(id==='gemma-api-key-group'&&v==='google')||(id==='openrouter-api-key-group'&&v==='openrouter')?'':'none';
      });
      if(GHE.Core)GHE.Core.Config.set('apiMode',v);
      
      // Update privacy badge text based on API mode
      const privacyText = $('privacy-text');
      if(privacyText) {
        if(v === 'google' || v === 'openrouter') {
          privacyText.textContent = '☁️ Cloud API Powered';
        } else {
          privacyText.textContent = '🔒 100% Local & Encrypted';
        }
      }
    });

    // ── Toggle key visibility
    const toggleKeyVis = (inputId, btn) => {
      const inp=$(inputId); if(!inp||!btn)return;
      const isPw=inp.type==='password'; inp.type=isPw?'text':'password';
      btn.classList.toggle('visible',!isPw);
    };
    on($('toggle-gemma-key'), CHAT, (e) => toggleKeyVis('gemma-api-key',e.currentTarget));
    on($('toggle-openrouter-key'), CHAT, (e) => toggleKeyVis('openrouter-api-key',e.currentTarget));
    on($('gemma-api-key'), 'change', (e) => GHE.Core.Storage.set('gemma-api-key', e.target.value));
    on($('openrouter-api-key'), 'change', (e) => GHE.Core.Storage.set('openrouter-api-key', e.target.value));

    // ── Auto-detect
    on($('btn-auto-detect'), CHAT, autoDetect);

    // ── Clinical
    on($('btn-save-clinical'), CHAT, saveClinicalProfile);

    // ── Troubleshooting
    on($('btn-test-backend'), CHAT, testBackend);
    on($('btn-clear-cache'), CHAT, clearAppCache);
    on($('btn-reset-settings'), CHAT, resetAllSettings);

    // ── Header
    on($('btn-reconnect'), CHAT, reconnect);
    on($('btn-sidebar-right-toggle'), CHAT, toggleRightSector);
    on($('btn-sector-close'), CHAT, closeRightSector);

    // ── Footer
    on($('file-input'), 'change', onFileSelected);
    on($('btn-upload'), CHAT, handleFileUpload);
    on($('btn-camera'), CHAT, openCamera);
    on($('btn-voice'), CHAT, toggleVoice);
    on($('remove-image'), CHAT, () => {
      state.imageAttachment=null;
      const p=$('image-preview'); if(p)p.hidden=true;
      const f=$('file-input'); if(f)f.value='';
    });

    // ── Camera
    on($('camera-cancel'), CHAT, closeCamera);
    on($('camera-capture'), CHAT, capturePhoto);
    on($('camera-switch'), CHAT, switchCamera);

    // ── Search
    on($('search-close'), CHAT, () => { const m=$('search-modal'); if(m)m.classList.remove('active'); });
    on($('search-input'), 'input', (e) => performSearch(e.target.value));
    const sm=$('search-modal');
    if(sm)on(sm.querySelector('.modal-overlay'), CHAT, () => sm.classList.remove('active'));

    // ── Help
    on($('help-close'), CHAT, () => { const m=$('help-modal'); if(m)m.classList.remove('active'); });
    on($('help-ok'), CHAT, () => { const m=$('help-modal'); if(m)m.classList.remove('active'); });
    const hm=$('help-modal');
    if(hm)on(hm.querySelector('.modal-overlay'), CHAT, () => hm.classList.remove('active'));

    // ── Mood
    document.querySelectorAll('.mood-btn').forEach(b => {
      on(b, CHAT, () => {
        document.querySelectorAll('.mood-btn').forEach(x => x.classList.remove('selected'));
        b.classList.add('selected');
        selectedMood=parseInt(b.dataset.mood);
      });
    });
    on($('btn-save-mood'), CHAT, saveMood);

    // ── Logo / disclosure
    on($('logo-new-chat'), CHAT, createNewSession);
    on($('disclaimer-accept'), CHAT, () => {
      localStorage.setItem('ghe_disclaimer_accepted','true');
      const m=$('disclaimer-modal'); if(m)m.classList.remove('active');
    });

    } catch (e) { console.warn('[App] event registration error:', e); }
  };

  // ── i18n Apply ────────────────────────────────────────────────────────────

  const applyLanguage = (lang) => {
    try {
      document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.dataset.i18n;
        const translated = t(key);
        if (translated !== key) el.textContent = translated;
      });
      document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
        const key = el.dataset.i18nPlaceholder;
        el.placeholder = t(key);
      });
    } catch (e) { console.error('[i18n] applyLanguage error:', e); }
  };

  // ── Restore saved config to UI ──────────────────────────────────────────────

  const restoreSettingsUI = () => {
    try {
      const config = GHE.Core.Config.getAll();

      // Theme
      const savedTheme = config.theme || 'dark';
      document.querySelectorAll('.theme-btn').forEach(b => {
        b.classList.toggle('active', b.dataset.theme === savedTheme);
      });
      document.documentElement.setAttribute('data-theme', savedTheme);

      // Language
      const savedLang = config.lang || 'en';
      document.querySelectorAll('.lang-btn').forEach(b => {
        b.classList.toggle('active', b.dataset.lang === savedLang);
      });
      state.lang = savedLang;
      applyLanguage(savedLang);

      // Feature toggles
      const toggleMap = {
        'toggle-research': 'researchMode',
        'toggle-thinking': 'showThinking',
        'toggle-camera': 'cameraEnabled',
        'toggle-voice': 'voiceEnabled',
      };
      Object.entries(toggleMap).forEach(([id, key]) => {
        const el = $(id);
        if (el) {
          const val = config[key];
          if (val !== undefined) el.checked = val;
        }
      });

      // Camera button visibility
      const camBtn = $('btn-camera');
      if (camBtn) camBtn.style.display = config.cameraEnabled ? '' : 'none';

      // API mode
      const savedMode = config.apiMode || 'local';
      const modeSelect = $('api-mode-select');
      if (modeSelect) {
        modeSelect.value = savedMode;
        const gemmaGroup = $('gemma-api-key-group');
        const openrouterGroup = $('openrouter-api-key-group');
        if (gemmaGroup) gemmaGroup.style.display = savedMode === 'google' ? '' : 'none';
        if (openrouterGroup) openrouterGroup.style.display = savedMode === 'openrouter' ? '' : 'none';
      }
      
      // Update privacy badge based on saved API mode
      const privacyText = $('privacy-text');
      if (privacyText) {
        if (savedMode === 'google' || savedMode === 'openrouter') {
          privacyText.textContent = '☁️ Cloud API Powered';
        } else {
          privacyText.textContent = '🔒 100% Local & Encrypted';
        }
      }

      // Restore saved API keys
      const savedGemmaKey = GHE.Core.Storage.get('gemma-api-key', '');
      const savedOpenrouterKey = GHE.Core.Storage.get('openrouter-api-key', '');
      const gemmaInput = $('gemma-api-key');
      const openrouterInput = $('openrouter-api-key');
      if (gemmaInput && savedGemmaKey) gemmaInput.value = savedGemmaKey;
      if (openrouterInput && savedOpenrouterKey) openrouterInput.value = savedOpenrouterKey;

      // Clinical profile placeholders (from stored data)
      GHE.Core.ClinicalProfile.get().then(p => {
        ['allergies','conditions','medications','age','weight','notes'].forEach(f => {
          const el = $(`clinical-${f}`);
          if (el && p[f]) el.value = p[f];
        });
      }).catch(() => {});
    } catch (e) { console.error('[Settings] restoreSettingsUI error:', e); }
  };

  window.addEventListener('DOMContentLoaded', init);

  // ── Public API ─────────────────────────────────────────────────────────────

  GHE.App = {
    copyMessage: (id) => {
      const m = state.messages.find(msg => msg.id === id);
      if (m) GHE.Core.copyToClipboard(m.content).then(() => GHE.Core.showToast('Copied to clipboard.'));
    },
    deleteMessage: (id) => {
      state.messages = state.messages.filter(m => m.id !== id);
      els.messagesContainer.innerHTML = '';
      state.messages.forEach(renderMessage);
      if (state.currentSession) {
        state.currentSession.messages = state.messages;
        GHE.Core.ChatStorage.saveSession(state.currentSession);
      }
    },
    loadSession
  };

})(window);
ndow.GHE || {}; 
  window.GHE = GHE;

  // ── State Management ───────────────────────────────────────────────────────
  
  const state = {
    currentSession:     null,
    messages:           [],
    isGenerating:       false,
    abortController:    null,
    lang:               'en',
    theme:              'dark',
    sidebarCollapsed:   false,
    rightSectorOpen:    false,
    imageAttachment:    null,
    isRecording:        false,
    disclaimerAccepted: false,
    showThinking:       true,
    visionSupported:    true
  };
  GHE.State = state;

  // ── Selectors & Helpers ────────────────────────────────────────────────────

  const $  = (id) => document.getElementById(id);
  const on = (el, evt, fn) => el?.addEventListener(evt, fn);
  const t  = (key) => GHE.Core.t(key, state.lang);

  const icons = {
    copy:    '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>',
    delete:  '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>',
    refresh: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M23 4v6h-6"/><path d="M1 20v-6h6"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>',
    close:   '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M18 6L6 18M6 6l12 12"/></svg>',
  };

  // ── DOM Cache ──────────────────────────────────────────────────────────────

  const els = {};
  const cacheElements = () => {
    const ids = [
      'disclaimer-modal', 'settings-modal', 'camera-modal', 'search-modal',
      'sidebar', 'messages-container', 'welcome-screen', 'message-input',
      'btn-send', 'btn-sidebar-new', 'connection-status', 'right-sector',
      'hw-gpu', 'hw-vram', 'hw-accel', 'session-title', 'btn-settings',
      'clinical-allergies', 'clinical-conditions', 'clinical-medications',
      'clinical-age', 'clinical-weight', 'clinical-notes', 'btn-save-clinical'
    ];
    ids.forEach(id => {
      const key = id.replace(/-([a-z])/g, (_, l) => l.toUpperCase());
      els[key] = $(id);
    });
  };

  // ── UI Actions ─────────────────────────────────────────────────────────────

  const openModal  = (m) => m?.classList.add('active');
  const closeModal = (m) => m?.classList.remove('active');

  const updateStatus = async () => {
    const health = await fetch(`${GHE.Core.getAPIBase()}/api/v1/health`).then(r => r.json()).catch(() => null);
    const online = !!health;

    state.visionSupported = health ? health.vision_supported !== false : true;

    // Sidebar indicator
    const dot = els.connectionStatus;
    if (dot) {
      dot.className = `connection-status ${online ? 'connected' : 'disconnected'}`;
      dot.querySelector('.status-text').textContent = online ? 'Connected' : 'Offline';
    }

    // Settings panel indicator
    const srv = $('server-status');
    if (srv) {
      srv.innerHTML = `<span class="status-dot ${online ? 'online' : 'offline'}"></span><span>${online ? 'Online' : 'Offline'}</span>`;
    }
  };

  const thinkingEl = () => document.getElementById('thinking-indicator');

  const thinkingIndicator = (show) => {
    let el = thinkingEl();
    if (show && !el) {
      el = document.createElement('div');
      el.id = 'thinking-indicator';
      el.className = 'message-wrapper assistant';
      el.innerHTML = '<div class="message assistant"><div class="message-content" style="color:var(--text-tertiary);font-style:italic;display:flex;align-items:center;gap:8px"><span class="thinking-dots"><span>.</span><span>.</span><span>.</span></span> Thinking</div></div>';
      els.messagesContainer.appendChild(el);
      els.messagesContainer.scrollTo({ top: els.messagesContainer.scrollHeight, behavior: 'smooth' });
    } else if (!show && el) {
      el.remove();
    }
  };

  const renderMessage = (msg) => {
    thinkingIndicator(false);
    const wrap = document.createElement('div');
    wrap.className = `message-wrapper ${msg.role}`;
    wrap.innerHTML = `
      <div class="message ${msg.role}">
        <div class="message-content">${GHE.Core.formatMarkdown(msg.content)}</div>
        <div class="message-actions">
          <button class="btn-action" title="Copy" onclick="GHE.App.copyMessage('${msg.id}')">${icons.copy}</button>
          <button class="btn-action" title="Delete" onclick="GHE.App.deleteMessage('${msg.id}')">${icons.delete}</button>
        </div>
      </div>
    `;
    els.messagesContainer.appendChild(wrap);
    els.messagesContainer.scrollTo({ top: els.messagesContainer.scrollHeight, behavior: 'smooth' });
  };

  // ── Session Management ─────────────────────────────────────────────────────

  const loadSession = async (id) => {
    const session = await GHE.Core.ChatStorage.getSession(id);
    if (!session) return;
    
    state.currentSession = session;
    state.messages = session.messages || [];
    els.messagesContainer.innerHTML = '';
    els.welcomeScreen.hidden = true;
    els.sessionTitle.textContent = session.title || 'Conversation';
    state.messages.forEach(renderMessage);
  };

  const createNewSession = () => {
    if (state.isGenerating) {
      GHE.Core.showToast('Please wait for the response to finish.', 'info');
      return;
    }
    state.currentSession = null;
    state.messages = [];
    els.messagesContainer.innerHTML = '';
    els.welcomeScreen.hidden = false;
    els.sessionTitle.textContent = 'Gemma Health Edge';
  };

  // ── Chat Flow ──────────────────────────────────────────────────────────────

  const sendMessage = async () => {
    const text = els.messageInput.value.trim();
    if (!text || state.isGenerating) return;

    if (!state.currentSession) {
      state.currentSession = { id: GHE.Core.generateId(), title: text.substring(0, 30) + '...', messages: [] };
    }

    els.messageInput.value = '';
    els.welcomeScreen.hidden = true;

    const userMsg = { id: GHE.Core.generateId(), role: 'user', content: text };
    state.messages.push(userMsg);
    renderMessage(userMsg);

    state.isGenerating = true;
    els.btnSend.disabled = true;
    els.btnSend.classList.add('generating');
    thinkingIndicator(true);

    try {
      const mode = GHE.Core.Config.get('apiMode');
      const apiKey = mode === 'google' ? GHE.Core.Storage.get('gemma-api-key', '')
                   : mode === 'openrouter' ? GHE.Core.Storage.get('openrouter-api-key', '')
                   : '';
      const resp = await fetch(`${GHE.Core.getAPIBase()}/api/v1/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          messages: state.messages,
          mode:     mode,
          research: GHE.Core.Config.get('researchMode'),
          api_key:  apiKey,
        })
      });

      if (!resp.ok) {
        const errBody = await resp.text().catch(() => '');
        throw new Error(errBody ? `${resp.status}: ${errBody.substring(0, 200)}` : `HTTP ${resp.status}`);
      }

      const data = await resp.json();
      const assistantMsg = { id: GHE.Core.generateId(), role: 'assistant', content: data.content };
      state.messages.push(assistantMsg);
      renderMessage(assistantMsg);

      const st = $('stat-ttft'); if (st && data.ttft_ms) st.textContent = data.ttft_ms > 0 ? `${data.ttft_ms.toFixed(0)}ms` : '-';
      const st2 = $('stat-tps'); if (st2 && data.tps) st2.textContent = data.tps > 0 ? `${data.tps.toFixed(1)} t/s` : '-';
      const st3 = $('stat-time'); if (st3 && data.total_time_ms) st3.textContent = data.total_time_ms > 0 ? `${(data.total_time_ms / 1000).toFixed(1)}s` : '-';
      
      state.currentSession.messages = state.messages;
      await GHE.Core.ChatStorage.saveSession(state.currentSession);
    } catch (e) {
      GHE.Core.showToast(e.message?.includes('503') ? 'Server busy — model still loading. Retry in a few seconds.' : e.message || 'Failed to get response.', 'error');
    } finally {
      state.isGenerating = false;
      els.btnSend.disabled = false;
      els.btnSend.classList.remove('generating');
    }
  };

  // ── Settings & Clinical Profile ───────────────────────────────────────────

  const loadClinicalProfile = async () => {
    const p = await GHE.Core.ClinicalProfile.get();
    if (els.clinicalAllergies)   els.clinicalAllergies.value   = p.allergies || '';
    if (els.clinicalConditions)  els.clinicalConditions.value  = p.conditions || '';
    if (els.clinicalMedications) els.clinicalMedications.value = p.medications || '';
    if (els.clinicalAge)         els.clinicalAge.value         = p.age || '';
    if (els.clinicalWeight)      els.clinicalWeight.value      = p.weight || '';
    if (els.clinicalNotes)       els.clinicalNotes.value       = p.notes || '';
  };

  const saveClinicalProfile = async () => {
    const data = {
      allergies:   els.clinicalAllergies.value,
      conditions:  els.clinicalConditions.value,
      medications: els.clinicalMedications.value,
      age:         els.clinicalAge.value,
      weight:      els.clinicalWeight.value,
      notes:       els.clinicalNotes.value
    };
    const ok = await GHE.Core.ClinicalProfile.save(data);
    if (ok) GHE.Core.showToast('Clinical profile saved locally.', 'success');
  };

  // ── Settings Tab Navigation ───────────────────────────────────────────────

  const switchSettingsTab = (tabId) => {
    document.querySelectorAll('.settings-nav-item').forEach(b => {
      b.classList.remove('active');
      b.setAttribute('aria-selected', 'false');
    });
    document.querySelectorAll('.settings-panel').forEach(p => {
      p.classList.remove('active');
      p.hidden = true;
    });
    const tabBtn = document.querySelector(`.settings-nav-item[data-tab="${tabId}"]`);
    if (tabBtn) { tabBtn.classList.add('active'); tabBtn.setAttribute('aria-selected', 'true'); }
    const panel = $(`tab-${tabId}`);
    if (panel) { panel.classList.add('active'); panel.hidden = false; }
  };

  // ── File / Image Upload ──────────────────────────────────────────────────

  const handleFileUpload = () => {
    if (!state.visionSupported) {
      GHE.Core.showToast('Cannot read image input (this model does not support image input).', 'error');
      return;
    }
    const input = $('file-input');
    if (!input) return;
    input.click();
  };

  const onFileSelected = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!state.visionSupported) {
      GHE.Core.showToast(`Cannot read "${file.name}" (this model does not support image input).`, 'error');
      return;
    }
    const preview = $('image-preview');
    const img = $('preview-img');
    if (preview && img) {
      preview.hidden = false;
      img.src = URL.createObjectURL(file);
    }
    state.imageAttachment = await GHE.Core.resizeImage(file);
  };

  // ── Camera ────────────────────────────────────────────────────────────────

  let cameraStream = null;

  const openCamera = async () => {
    if (!state.visionSupported) {
      GHE.Core.showToast('Cannot read image input (this model does not support image input).', 'error');
      return;
    }
    const modal = $('camera-modal');
    const video = $('camera-video');
    if (!modal || !video) return;
    try {
      cameraStream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
      video.srcObject = cameraStream;
      openModal(modal);
    } catch (e) {
      GHE.Core.showToast('Camera access denied or unavailable.', 'error');
    }
  };

  const closeCamera = () => {
    if (cameraStream) { cameraStream.getTracks().forEach(t => t.stop()); cameraStream = null; }
    closeModal($('camera-modal'));
  };

  const capturePhoto = () => {
    if (!state.visionSupported) {
      GHE.Core.showToast('Cannot read image input (this model does not support image input).', 'error');
      return;
    }
    const video = $('camera-video');
    const canvas = $('camera-canvas');
    const preview = $('image-preview');
    const img = $('preview-img');
    if (!video || !canvas || !preview || !img) return;
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    canvas.getContext('2d').drawImage(video, 0, 0);
    const dataUrl = canvas.toDataURL('image/jpeg', 0.85);
    state.imageAttachment = dataUrl;
    preview.hidden = false;
    img.src = dataUrl;
    closeCamera();
  };

  const switchCamera = async () => {
    if (!cameraStream) return;
    const facing = cameraStream.getVideoTracks()[0]?.getSettings().facingMode;
    const newFacing = facing === 'environment' ? 'user' : 'environment';
    cameraStream.getTracks().forEach(t => t.stop());
    try {
      cameraStream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: newFacing } });
      const video = $('camera-video');
      if (video) video.srcObject = cameraStream;
    } catch (e) {
      GHE.Core.showToast('Failed to switch camera.', 'error');
    }
  };

  // ── Voice Input ──────────────────────────────────────────────────────────

  let voiceRecognition = null;

  const toggleVoice = () => {
    if (state.isRecording) {
      if (voiceRecognition) { voiceRecognition.stop(); voiceRecognition = null; }
      state.isRecording = false;
      const btn = $('btn-voice');
      if (btn) btn.innerHTML = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 1a3 3 0 00-3 3v8a3 3 0 006 0V4a3 3 0 00-3-3z"/><path d="M19 10v2a7 7 0 01-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/></svg>';
      return;
    }
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      GHE.Core.showToast('Voice input not supported in this browser.', 'error');
      return;
    }
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    voiceRecognition = new SpeechRecognition();
    voiceRecognition.lang = state.lang;
    voiceRecognition.continuous = false;
    voiceRecognition.interimResults = false;
    voiceRecognition.onresult = (e) => {
      const transcript = e.results[0][0].transcript;
      els.messageInput.value += transcript;
      state.isRecording = false;
      const btn = $('btn-voice');
      if (btn) btn.innerHTML = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 1a3 3 0 00-3 3v8a3 3 0 006 0V4a3 3 0 00-3-3z"/><path d="M19 10v2a7 7 0 01-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/></svg>';
    };
    voiceRecognition.onerror = () => {
      state.isRecording = false;
      GHE.Core.showToast('Voice recognition error.', 'error');
      const btn = $('btn-voice');
      if (btn) btn.innerHTML = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 1a3 3 0 00-3 3v8a3 3 0 006 0V4a3 3 0 00-3-3z"/><path d="M19 10v2a7 7 0 01-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/></svg>';
    };
    voiceRecognition.start();
    state.isRecording = true;
    const btn = $('btn-voice');
    if (btn) btn.innerHTML = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2"><rect x="6" y="3" width="4" height="18" rx="1"/><rect x="14" y="3" width="4" height="18" rx="1"/></svg>';
  };

  // ── Export Chat ──────────────────────────────────────────────────────────

  const exportChat = () => {
    if (state.messages.length === 0) {
      GHE.Core.showToast('No messages to export.', 'info');
      return;
    }
    const lines = state.messages.map(m => `[${m.role.toUpperCase()}]\n${m.content}`).join('\n---\n');
    const blob = new Blob([lines], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `gemma-health-chat-${Date.now()}.txt`;
    a.click();
    URL.revokeObjectURL(url);
    GHE.Core.showToast('Chat exported.', 'success');
  };

  // ── Clear Chat ──────────────────────────────────────────────────────────

  const clearChat = () => {
    if (state.isGenerating) {
      GHE.Core.showToast('Please wait for the response to finish.', 'info');
      return;
    }
    if (state.messages.length === 0) return;
    state.messages = [];
    els.messagesContainer.innerHTML = '';
    els.welcomeScreen.hidden = false;
  };

  // ── Search Sessions ─────────────────────────────────────────────────────

  const openSearch = () => {
    openModal($('search-modal'));
    const input = $('search-input');
    if (input) { input.value = ''; input.focus(); }
    const results = $('search-results');
    if (results) results.innerHTML = '<div class="search-hint" style="padding:1rem;color:var(--text-tertiary);font-size:0.85rem">Type to search your conversations...</div>';
  };

  const performSearch = async (query) => {
    const results = $('search-results');
    if (!results) return;
    if (!query.trim()) {
      results.innerHTML = '<div class="search-hint" style="padding:1rem;color:var(--text-tertiary);font-size:0.85rem">Type to search your conversations...</div>';
      return;
    }
    results.innerHTML = '<div style="padding:1rem;color:var(--text-tertiary)">Searching...</div>';
    const sessions = await GHE.Core.ChatStorage.getSessions();
    const matched = sessions.filter(s => 
      s.title?.toLowerCase().includes(query.toLowerCase()) ||
      s.messages?.some(m => m.content?.toLowerCase().includes(query.toLowerCase()))
    );
    if (matched.length === 0) {
      results.innerHTML = '<div style="padding:1rem;color:var(--text-tertiary)">No results found.</div>';
      return;
    }
    results.innerHTML = matched.map(s => `
      <div class="search-result-item" data-session-id="${s.id}" style="padding:0.6rem 0.8rem;cursor:pointer;border-bottom:1px solid var(--border-color);display:flex;align-items:center;gap:0.6rem">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>
        <div><div style="font-weight:500;font-size:0.85rem">${GHE.Core.sanitizeHTML(s.title || 'Untitled')}</div><div style="font-size:0.7rem;color:var(--text-tertiary)">${s.messages?.length || 0} messages</div></div>
      </div>
    `).join('');
    results.querySelectorAll('.search-result-item').forEach(el => {
      el.addEventListener('click', () => {
        loadSession(el.dataset.sessionId);
        closeModal($('search-modal'));
      });
    });
  };

  // ── Mood Tracker ──────────────────────────────────────────────────────────

  let selectedMood = 0;

  const saveMood = async () => {
    if (selectedMood === 0) { GHE.Core.showToast('Select a mood first.', 'info'); return; }
    const note = $('mood-note-input')?.value || '';
    const today = new Date().toISOString().split('T')[0];
    const ok = await GHE.Core.MoodTracker.saveMood(today, selectedMood, note);
    if (ok) {
      GHE.Core.showToast('Mood saved!', 'success');
      if ($('mood-note-input')) $('mood-note-input').value = '';
      selectedMood = 0;
      document.querySelectorAll('.mood-btn').forEach(b => b.classList.remove('selected'));
    }
  };

  // ── Auto-detect Server ───────────────────────────────────────────────────

  const autoDetect = async () => {
    const statusEl = $('server-status');
    if (statusEl) {
      statusEl.innerHTML = '<span class="status-dot checking"></span><span>Scanning...</span>';
    }
    const urls = ['http://127.0.0.1:8080', 'http://127.0.0.1:11434', 'http://localhost:8080', 'http://localhost:11434'];
    for (const url of urls) {
      try {
        const resp = await fetch(`${url}/api/v1/health`, { signal: AbortSignal.timeout(2000) });
        if (resp.ok) {
          GHE.Core.Config.set('middlemanUrl', url);
          if (statusEl) statusEl.innerHTML = `<span class="status-dot online"></span><span>Found: ${url}</span>`;
          updateStatus();
          return;
        }
      } catch (e) { continue; }
    }
    if (statusEl) statusEl.innerHTML = '<span class="status-dot offline"></span><span>No server found</span>';
    GHE.Core.showToast('Could not auto-detect a running server.', 'error');
  };

  // ── Troubleshooting ─────────────────────────────────────────────────────

  const testBackend = async () => {
    GHE.Core.showToast('Testing backend connection...', 'info');
    await updateStatus();
    const cs = $('connection-status');
    if (cs?.classList.contains('connected')) GHE.Core.showToast('Backend is reachable.', 'success');
    else GHE.Core.showToast('Backend unreachable. Check your server.', 'error');
  };

  const clearAppCache = async () => {
    if ('caches' in window) {
      const keys = await caches.keys();
      await Promise.all(keys.map(k => caches.delete(k)));
    }
    localStorage.clear();
    GHE.Core.showToast('Cache and local storage cleared. Reloading...', 'success');
    setTimeout(() => location.reload(), 1000);
  };

  const resetAllSettings = () => {
    GHE.Core.Config.reset();
    GHE.Core.showToast('Settings reset. Reloading...', 'success');
    setTimeout(() => location.reload(), 1000);
  };

  // ── Reconnect ────────────────────────────────────────────────────────────

  const reconnect = async () => {
    const btn = $('btn-reconnect');
    if (btn) { btn.disabled = true; btn.innerHTML = '<span>Connecting...</span>'; }
    await updateStatus();
    if (btn) { btn.disabled = false; btn.style.display = 'none'; }
  };

  // ── Right Sector Toggle ─────────────────────────────────────────────────

  const toggleRightSector = () => {
    state.rightSectorOpen = !state.rightSectorOpen;
    const sector = $('right-sector');
    if (sector) sector.classList.toggle('collapsed', !state.rightSectorOpen);
  };

  const closeRightSector = () => {
    state.rightSectorOpen = false;
    const sector = $('right-sector');
    if (sector) sector.classList.add('collapsed');
  };

  // ── Help Modal ──────────────────────────────────────────────────────────

  const openHelp = () => openModal($('help-modal'));
  const closeHelp = () => closeModal($('help-modal'));

  // ── Initialization ─────────────────────────────────────────────────────────

  const init = () => {
    console.log('[App] init() started');
    // Phase 1: Register all event handlers FIRST (never skipped by errors)
    registerEventHandlers();

    // Phase 2: Setup UI state from saved config
    try {
      cacheElements();
      restoreSettingsUI();
      updateStatus();
      loadClinicalProfile();
      applyLanguage(state.lang);
      renderCalendar();

      // Hardware Diagnostics - prefer backend health data over WebGPU
      fetch(`${GHE.Core.getAPIBase()}/api/v1/health`).then(r => r.json()).then(h => {
        if (els.hwGpu) els.hwGpu.textContent = h.gpu || 'Unknown';
        if (els.hwVram) els.hwVram.textContent = h.vram_gb ? `${h.vram_gb} GB` : 'N/A';
        if (els.hwAccel) els.hwAccel.textContent = h.accelerator || 'CPU';
      }).catch(() => {
        if (GHE.Core) GHE.Core.detectGPU().then(hw => {
          if (els.hwGpu) els.hwGpu.textContent = hw.gpu;
          if (els.hwVram) els.hwVram.textContent = hw.vram;
          if (els.hwAccel) els.hwAccel.textContent = hw.accel;
        }).catch(() => {});
      });

      // Disclaimer
      if (!localStorage.getItem('ghe_disclaimer_accepted')) {
        const dm = $('disclaimer-modal');
        if (dm) dm.classList.add('active');
      }

      // Periodic checks
      setInterval(updateStatus, 30000);
    } catch (e) { console.error('[App] init setup error:', e); }
  };

  // ── Calendar Render ────────────────────────────────────────────────────────

  const renderCalendar = () => {
    const container = $('calendar-body');
    if (!container) return;
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const firstDay = new Date(year, month, 1).getDay();
    const today = now.getDate();

    let html = '<table class="cal-table" style="width:100%;border-collapse:collapse;font-size:0.72rem"><thead><tr>';
    ['Su','Mo','Tu','We','Th','Fr','Sa'].forEach(d => { html += `<th style="padding:2px;text-align:center;color:var(--text-tertiary)">${d}</th>`; });
    html += '</tr></thead><tbody><tr>';
    for (let i = 0; i < firstDay; i++) html += '<td style="padding:2px"></td>';
    for (let day = 1; day <= daysInMonth; day++) {
      const isToday = day === today ? ' style="background:var(--accent-1);color:#fff;border-radius:50%;font-weight:700"' : ' style="color:var(--text-primary)"';
      html += `<td align="center" style="padding:2px"><span${isToday}>${day}</span></td>`;
      if ((firstDay + day) % 7 === 0 && day < daysInMonth) html += '</tr><tr>';
    }
    html += '</tr></tbody></table>';
    container.innerHTML = html;

    // Update count
    const countEl = $('cal-count');
    if (countEl) countEl.textContent = 'Today: ' + today;
  };

  // ── Event Handlers (always registered, never skipped) ──────────────────────

  const registerEventHandlers = () => {
    console.log('[App] Registering event handlers...');
    try {
    const CHAT = 'click';
    // ── Chat
    on($('btn-send'), CHAT, sendMessage);
    on($('message-input'), 'keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
    });

    // ── Sidebar
    on($('btn-sidebar-new'), CHAT, createNewSession);
    on($('btn-sidebar-search'), CHAT, openSearch);
    on($('btn-sidebar-clear'), CHAT, clearChat);
    on($('btn-sidebar-export'), CHAT, exportChat);
    on($('btn-help'), CHAT, openHelp);
    on($('btn-settings'), CHAT, () => { const m=$('settings-modal'); if(m)m.classList.add('active'); });
    on($('btn-sidebar-expand'), CHAT, () => { const s=$('sidebar'); if(s)s.classList.remove('collapsed'); });
    on($('btn-sidebar-collapse'), CHAT, () => { const s=$('sidebar'); if(s)s.classList.add('collapsed'); });

    // ── Settings modal
    on($('settings-close'), CHAT, () => { const m=$('settings-modal'); if(m)m.classList.remove('active'); });
    on($('settings-overlay'), CHAT, () => { const m=$('settings-modal'); if(m)m.classList.remove('active'); });

    // Settings tab nav
    document.querySelectorAll('.settings-nav-item').forEach(b => {
      on(b, CHAT, () => {
        document.querySelectorAll('.settings-nav-item').forEach(x => { x.classList.remove('active'); x.setAttribute('aria-selected','false'); });
        document.querySelectorAll('.settings-panel').forEach(p => { p.classList.remove('active'); p.hidden = true; });
        b.classList.add('active'); b.setAttribute('aria-selected','true');
        const p = $(`tab-${b.dataset.tab}`);
        if (p) { p.classList.add('active'); p.hidden = false; }
      });
    });

    // ── Theme
    document.querySelectorAll('.theme-btn').forEach(b => {
      on(b, CHAT, () => {
        document.querySelectorAll('.theme-btn').forEach(x => x.classList.remove('active'));
        b.classList.add('active');
        document.documentElement.setAttribute('data-theme', b.dataset.theme);
        if (GHE.Core) GHE.Core.Config.set('theme', b.dataset.theme);
      });
    });

    // ── Language
    document.querySelectorAll('.lang-btn').forEach(b => {
      on(b, CHAT, () => {
        document.querySelectorAll('.lang-btn').forEach(x => x.classList.remove('active'));
        b.classList.add('active');
        state.lang = b.dataset.lang;
        if (GHE.Core) GHE.Core.Config.set('lang', b.dataset.lang);
        applyLanguage(b.dataset.lang);
      });
    });

    // ── Feature toggles
    on($('toggle-research'), 'change', (e) => { if(GHE.Core)GHE.Core.Config.set('researchMode',e.target.checked); });
    on($('toggle-thinking'), 'change', (e) => { if(GHE.Core)GHE.Core.Config.set('showThinking',e.target.checked); state.showThinking=e.target.checked; });
    on($('toggle-camera'), 'change', (e) => {
      if(GHE.Core)GHE.Core.Config.set('cameraEnabled',e.target.checked);
      const cb=$('btn-camera'); if(cb)cb.style.display=e.target.checked?'':'none';
    });
    on($('toggle-voice'), 'change', (e) => { if(GHE.Core)GHE.Core.Config.set('voiceEnabled',e.target.checked); });

    // ── API mode
    on($('api-mode-select'), 'change', (e) => {
      const v=e.target.value;
      ['gemma-api-key-group','openrouter-api-key-group'].forEach(id=>{
        const el=$(id); if(el)el.style.display=(id==='gemma-api-key-group'&&v==='google')||(id==='openrouter-api-key-group'&&v==='openrouter')?'':'none';
      });
      if(GHE.Core)GHE.Core.Config.set('apiMode',v);
    });

    // ── Toggle key visibility
    const toggleKeyVis = (inputId, btn) => {
      const inp=$(inputId); if(!inp||!btn)return;
      const isPw=inp.type==='password'; inp.type=isPw?'text':'password';
      btn.classList.toggle('visible',!isPw);
    };
    on($('toggle-gemma-key'), CHAT, (e) => toggleKeyVis('gemma-api-key',e.currentTarget));
    on($('toggle-openrouter-key'), CHAT, (e) => toggleKeyVis('openrouter-api-key',e.currentTarget));
    on($('gemma-api-key'), 'change', (e) => GHE.Core.Storage.set('gemma-api-key', e.target.value));
    on($('openrouter-api-key'), 'change', (e) => GHE.Core.Storage.set('openrouter-api-key', e.target.value));

    // ── Auto-detect
    on($('btn-auto-detect'), CHAT, autoDetect);

    // ── Clinical
    on($('btn-save-clinical'), CHAT, saveClinicalProfile);

    // ── Troubleshooting
    on($('btn-test-backend'), CHAT, testBackend);
    on($('btn-clear-cache'), CHAT, clearAppCache);
    on($('btn-reset-settings'), CHAT, resetAllSettings);

    // ── Header
    on($('btn-reconnect'), CHAT, reconnect);
    on($('btn-sidebar-right-toggle'), CHAT, toggleRightSector);
    on($('btn-sector-close'), CHAT, closeRightSector);

    // ── Footer
    on($('file-input'), 'change', onFileSelected);
    on($('btn-upload'), CHAT, handleFileUpload);
    on($('btn-camera'), CHAT, openCamera);
    on($('btn-voice'), CHAT, toggleVoice);
    on($('remove-image'), CHAT, () => {
      state.imageAttachment=null;
      const p=$('image-preview'); if(p)p.hidden=true;
      const f=$('file-input'); if(f)f.value='';
    });

    // ── Camera
    on($('camera-cancel'), CHAT, closeCamera);
    on($('camera-capture'), CHAT, capturePhoto);
    on($('camera-switch'), CHAT, switchCamera);

    // ── Search
    on($('search-close'), CHAT, () => { const m=$('search-modal'); if(m)m.classList.remove('active'); });
    on($('search-input'), 'input', (e) => performSearch(e.target.value));
    const sm=$('search-modal');
    if(sm)on(sm.querySelector('.modal-overlay'), CHAT, () => sm.classList.remove('active'));

    // ── Help
    on($('help-close'), CHAT, () => { const m=$('help-modal'); if(m)m.classList.remove('active'); });
    on($('help-ok'), CHAT, () => { const m=$('help-modal'); if(m)m.classList.remove('active'); });
    const hm=$('help-modal');
    if(hm)on(hm.querySelector('.modal-overlay'), CHAT, () => hm.classList.remove('active'));

    // ── Mood
    document.querySelectorAll('.mood-btn').forEach(b => {
      on(b, CHAT, () => {
        document.querySelectorAll('.mood-btn').forEach(x => x.classList.remove('selected'));
        b.classList.add('selected');
        selectedMood=parseInt(b.dataset.mood);
      });
    });
    on($('btn-save-mood'), CHAT, saveMood);

    // ── Logo / disclosure
    on($('logo-new-chat'), CHAT, createNewSession);
    on($('disclaimer-accept'), CHAT, () => {
      localStorage.setItem('ghe_disclaimer_accepted','true');
      const m=$('disclaimer-modal'); if(m)m.classList.remove('active');
    });

    } catch (e) { console.warn('[App] event registration error:', e); }
  };

  // ── i18n Apply ────────────────────────────────────────────────────────────

  const applyLanguage = (lang) => {
    try {
      document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.dataset.i18n;
        const translated = t(key);
        if (translated !== key) el.textContent = translated;
      });
      document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
        const key = el.dataset.i18nPlaceholder;
        el.placeholder = t(key);
      });
    } catch (e) { console.error('[i18n] applyLanguage error:', e); }
  };

  // ── Restore saved config to UI ──────────────────────────────────────────────

  const restoreSettingsUI = () => {
    try {
      const config = GHE.Core.Config.getAll();

      // Theme
      const savedTheme = config.theme || 'dark';
      document.querySelectorAll('.theme-btn').forEach(b => {
        b.classList.toggle('active', b.dataset.theme === savedTheme);
      });
      document.documentElement.setAttribute('data-theme', savedTheme);

      // Language
      const savedLang = config.lang || 'en';
      document.querySelectorAll('.lang-btn').forEach(b => {
        b.classList.toggle('active', b.dataset.lang === savedLang);
      });
      state.lang = savedLang;
      applyLanguage(savedLang);

      // Feature toggles
      const toggleMap = {
        'toggle-research': 'researchMode',
        'toggle-thinking': 'showThinking',
        'toggle-camera': 'cameraEnabled',
        'toggle-voice': 'voiceEnabled',
      };
      Object.entries(toggleMap).forEach(([id, key]) => {
        const el = $(id);
        if (el) {
          const val = config[key];
          if (val !== undefined) el.checked = val;
        }
      });

      // Camera button visibility
      const camBtn = $('btn-camera');
      if (camBtn) camBtn.style.display = config.cameraEnabled ? '' : 'none';

      // API mode
      const savedMode = config.apiMode || 'local';
      const modeSelect = $('api-mode-select');
      if (modeSelect) {
        modeSelect.value = savedMode;
        const gemmaGroup = $('gemma-api-key-group');
        const openrouterGroup = $('openrouter-api-key-group');
        if (gemmaGroup) gemmaGroup.style.display = savedMode === 'google' ? '' : 'none';
        if (openrouterGroup) openrouterGroup.style.display = savedMode === 'openrouter' ? '' : 'none';
      }

      // Restore saved API keys
      const savedGemmaKey = GHE.Core.Storage.get('gemma-api-key', '');
      const savedOpenrouterKey = GHE.Core.Storage.get('openrouter-api-key', '');
      const gemmaInput = $('gemma-api-key');
      const openrouterInput = $('openrouter-api-key');
      if (gemmaInput && savedGemmaKey) gemmaInput.value = savedGemmaKey;
      if (openrouterInput && savedOpenrouterKey) openrouterInput.value = savedOpenrouterKey;

      // Clinical profile placeholders (from stored data)
      GHE.Core.ClinicalProfile.get().then(p => {
        ['allergies','conditions','medications','age','weight','notes'].forEach(f => {
          const el = $(`clinical-${f}`);
          if (el && p[f]) el.value = p[f];
        });
      }).catch(() => {});
    } catch (e) { console.error('[Settings] restoreSettingsUI error:', e); }
  };

  window.addEventListener('DOMContentLoaded', init);

  // ── Public API ─────────────────────────────────────────────────────────────

  GHE.App = {
    copyMessage: (id) => {
      const m = state.messages.find(msg => msg.id === id);
      if (m) GHE.Core.copyToClipboard(m.content).then(() => GHE.Core.showToast('Copied to clipboard.'));
    },
    deleteMessage: (id) => {
      state.messages = state.messages.filter(m => m.id !== id);
      els.messagesContainer.innerHTML = '';
      state.messages.forEach(renderMessage);
      if (state.currentSession) {
        state.currentSession.messages = state.messages;
        GHE.Core.ChatStorage.saveSession(state.currentSession);
      }
    },
    loadSession
  };

})(window);
