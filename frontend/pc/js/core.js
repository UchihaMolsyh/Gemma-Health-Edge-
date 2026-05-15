/**
 * Gemma Health Edge — Core Utilities
 * 
 * Bundled: i18n, storage, config, PDF export, medical helpers.
 * Optimized for local-first, privacy-conscious medical AI.
 */

// ── Internationalization ──────────────────────────────────────────────────────

const dictionary = {
  en: { 
    appTitle: "Gemma Health Edge",
    disclaimer_title: "Medical Disclaimer & Terms", 
    disclaimer_text: "This AI health assistant provides information for educational purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment.\n\nAlways seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.\n\nIn case of emergency, call your local emergency number immediately.", 
    disclaimer_accept: "I Understand", 
    settings_title: "Settings", 
    status_checking: "Checking…", 
    status_online: "Online", 
    status_offline: "Offline", 
    input_placeholder: "Describe symptoms, ask a health question, or upload a photo…", 
    welcome_title: "Gemma Health Edge", 
    welcome_subtitle: "Advanced Offline Medical Intelligence Dashboard", 
    settings_thinking: "Show Thinking", 
    toast_copied: "Copied!", 
    toast_saved: "Saved!", 
    toast_error: "Error occurred", 
    thinking: "Thinking…",
    newSession: "New Session",
    serverOnline: "Online",
    serverOffline: "Offline",
    autoDetect: "Auto-detect",
    calendarTitle: "Health Calendar",
    moodLabel: "Mood",
    moodAverage: "Avg this month",
    cameraButton: "Camera",
    galleryButton: "Gallery",
    researchNote: "🔬 Wikipedia context added",
    notADoctor: "I'm not a doctor. Always consult a healthcare professional.",
    sessionHistory: "Session History",
    clearChat: "Clear",
    help: "Help",
    btn_clear_chat: "Clear",
    copyMessage: "Copy",
    exportChat: "Export Chat",
    privacyBadge: "100% Private",
    healthSector: "Health Sector",
    moodQuestion: "How are you feeling today?",
    moodNotePlaceholder: "Add a note (optional)...",
    medicalDisclaimer: "Medical Disclaimer",
    disclaimerText: "This assistant provides information only. It is not a substitute for professional medical advice, diagnosis, or treatment.",
    hwHardware: "Hardware",
    hwVRAM: "VRAM",
    hwAcceleration: "Acceleration",
    hwTTFT: "TTFT",
    hwTPS: "TPS",
    hwTotalTime: "TOTAL TIME",
    hwPrivacyMode: "Privacy Mode",
    hwPrivacyValue: "100% Offline",
    cardSymptomChecker: "Symptom Checker",
    cardSymptomDesc: "Headache and mild fever",
    cardMedicationInfo: "Medication Info",
    cardMedicationDesc: "Side effects of Ibuprofen",
    cardWellnessTips: "Wellness Tips",
    cardWellnessDesc: "Improve sleep schedule",
    cardHealthMetrics: "Health Metrics",
    cardHealthDesc: "Normal blood pressure",
    cardNutrition: "Nutrition",
    cardNutritionDesc: "Healthy diet advice",
    cardMentalHealth: "Mental Health",
    cardMentalDesc: "Stress management",
    cardFitnessPlan: "Fitness Plan",
    cardFitnessDesc: "Home workout routines",
    cardFirstAid: "First Aid",
    cardFirstAidDesc: "Treating minor burns",
    cardVaccinations: "Vaccinations",
    cardVaccinationsDesc: "Adult immunization schedule",
    cardLabResults: "Lab Results",
    cardLabResultsDesc: "Understanding blood tests",
    help_title: "🚀 Quick Start Guide",
    help_step1: "Just start typing! Describe your symptoms or ask a health question in the box at the bottom.",
    help_step2: "AI is not a doctor. We provide information, not medical advice. Always consult a professional.",
    help_step3: "Privacy First. Your data stays on your computer. Look for the 100% Private badge.",
    help_step4: "Emergency? If you have severe symptoms, call 911 or your local emergency number immediately.",
    help_got_it: "Got it!"
  },

    tab_server: "Server",
    tab_customization: "Customization",
    tab_language: "Language",
    tab_features: "Features",
    tab_clinical: "My Clinical Profile",
    tab_troubleshooting: "Troubleshooting",
    server_config_title: "Server Configuration",
    server_config_desc: "Configure your AI backend connection",
    custom_title: "Customization",
    custom_desc: "Personalize your interface appearance",
    lang_title: "Language",
    lang_desc: "Select your preferred language",
    features_title: "Features",
    features_desc: "Enable or disable additional features",
    clinical_title: "My Clinical Profile",
    clinical_desc: "Your medical information helps the AI provide personalized advice",
    trouble_title: "Troubleshooting",
    trouble_desc: "Diagnostic tools and common issue fixes",
    label_ai_backend: "AI Backend",
    label_gemma_key: "Gemma API Key",
    label_openrouter_key: "OpenRouter Key",
    label_theme: "Theme",
    label_research: "Research Mode (Wikipedia when online)",
    label_camera: "Enable Camera Button",
    label_voice: "Read Responses Aloud (TTS)",
    label_allergies: "Allergies",
    label_conditions: "Medical Conditions",
    label_medications: "Current Medications",
    label_age: "Age",
    label_weight: "Weight (kg)",
    label_notes: "Additional Notes",
    hint_allergies: "List all known allergies, separated by commas",
    hint_conditions: "Chronic conditions or ongoing health issues",
    hint_medications: "Include dosages if known. This helps avoid drug interaction warnings.",
    btn_save_profile: "Save Profile",
    trouble_diag_title: "Connection Diagnostics",
    trouble_sys_title: "System Information",
    trouble_faq_title: "Common Issues",
    clinical_disclaimer: "This data is stored locally on your device and sent with chat requests to personalize AI responses.",
    privacy_badge_text: "100% Local & Encrypted",
    history_label: "Chats",
    search_title: "Search Sessions",
    camera_take: "Take a Photo",
    camera_cancel: "Cancel",
    camera_capture: "Capture",
    mood_note_placeholder: "Add a note (optional)...",
    faq_slow: "AI responses are slow or timing out",
    faq_pdf: "PDF import is not working",
    faq_camera: "Camera button not appearing",
    faq_lang: "Language not changing",
  fr: { 
    appTitle: "Gemma Health Edge",
    disclaimer_title: "Avertissement Médical", 
    disclaimer_text: "Cet assistant santé IA fournit des informations à des fins éducatives uniquement...", 
    disclaimer_accept: "Je Comprends", 
    settings_title: "Paramètres",
    status_checking: "Vérification…",
    status_online: "En ligne",
    status_offline: "Hors ligne",
    input_placeholder: "Décrivez les symptômes...",
    welcome_title: "Gemma Health Edge",
    welcome_subtitle: "Tableau de bord intelligent médical hors ligne",
    settings_thinking: "Afficher la réflexion",
    toast_copied: "Copied!",
    toast_saved: "Saved!",
    toast_error: "Error occurred",
    thinking: "Thinking…",
    newSession: "New Session",
    serverOnline: "Online",
    serverOffline: "Offline",
    autoDetect: "Auto-detect",
    calendarTitle: "Health Calendar",
    moodLabel: "Mood",
    moodAverage: "Avg this month",
    cameraButton: "Camera",
    galleryButton: "Gallery",
    researchNote: "🔬 Wikipedia context added",
    notADoctor: "I'm not a doctor. Always consult a healthcare professional.",
    sessionHistory: "Session History",
    clearChat: "Clear",
    help: "Help",
    btn_clear_chat: "Clear",
    copyMessage: "Copy",
    exportChat: "Export Chat",
    privacyBadge: "100% Private",
    healthSector: "Health Sector",
    moodQuestion: "How are you feeling today?",
    moodNotePlaceholder: "Add a note (optional)...",
    medicalDisclaimer: "Medical Disclaimer",
    disclaimerText: "This assistant provides information only. It is not a substitute for professional medical advice, diagnosis, or treatment.",
    hwHardware: "Hardware",
    hwVRAM: "VRAM",
    hwAcceleration: "Acceleration",
    hwTTFT: "TTFT",
    hwTPS: "TPS",
    hwTotalTime: "TOTAL TIME",
    hwPrivacyMode: "Privacy Mode",
    hwPrivacyValue: "100% Offline",
    cardSymptomChecker: "Symptom Checker",
    cardSymptomDesc: "Headache and mild fever",
    cardMedicationInfo: "Medication Info",
    cardMedicationDesc: "Side effects of Ibuprofen",
    cardWellnessTips: "Wellness Tips",
    cardWellnessDesc: "Improve sleep schedule",
    cardHealthMetrics: "Health Metrics",
    cardHealthDesc: "Normal blood pressure",
    cardNutrition: "Nutrition",
    cardNutritionDesc: "Healthy diet advice",
    cardMentalHealth: "Mental Health",
    cardMentalDesc: "Stress management",
    cardFitnessPlan: "Fitness Plan",
    cardFitnessDesc: "Home workout routines",
    cardFirstAid: "First Aid",
    cardFirstAidDesc: "Treating minor burns",
    cardVaccinations: "Vaccinations",
    cardVaccinationsDesc: "Adult immunization schedule",
    cardLabResults: "Lab Results",
    cardLabResultsDesc: "Understanding blood tests",
  },
  de: { 
    appTitle: "Gemma Health Edge",
    disclaimer_title: "Medizinischer Haftungsausschluss", 
    disclaimer_text: "Dieser KI-Gesundheitsassistent dient ausschließlich Informationszwecken...", 
    disclaimer_accept: "Ich verstehe", 
    settings_title: "Einstellungen",
    status_checking: "Prüfung…",
    status_online: "Online",
    status_offline: "Offline",
    input_placeholder: "Symptome beschreiben...",
    welcome_title: "Gemma Health Edge",
    welcome_subtitle: "Erweitertes Offline-Dashboard für medizinische Intelligenz",
    settings_thinking: "Denkvorgang anzeigen",
    toast_copied: "Copied!",
    toast_saved: "Saved!",
    toast_error: "Error occurred",
    thinking: "Thinking…",
    newSession: "New Session",
    serverOnline: "Online",
    serverOffline: "Offline",
    autoDetect: "Auto-detect",
    calendarTitle: "Health Calendar",
    moodLabel: "Mood",
    moodAverage: "Avg this month",
    cameraButton: "Camera",
    galleryButton: "Gallery",
    researchNote: "🔬 Wikipedia context added",
    notADoctor: "I'm not a doctor. Always consult a healthcare professional.",
    sessionHistory: "Session History",
    clearChat: "Clear",
    help: "Help",
    btn_clear_chat: "Clear",
    copyMessage: "Copy",
    exportChat: "Export Chat",
    privacyBadge: "100% Private",
    healthSector: "Health Sector",
    moodQuestion: "How are you feeling today?",
    moodNotePlaceholder: "Add a note (optional)...",
    medicalDisclaimer: "Medical Disclaimer",
    disclaimerText: "This assistant provides information only. It is not a substitute for professional medical advice, diagnosis, or treatment.",
    hwHardware: "Hardware",
    hwVRAM: "VRAM",
    hwAcceleration: "Acceleration",
    hwTTFT: "TTFT",
    hwTPS: "TPS",
    hwTotalTime: "TOTAL TIME",
    hwPrivacyMode: "Privacy Mode",
    hwPrivacyValue: "100% Offline",
    cardSymptomChecker: "Symptom Checker",
    cardSymptomDesc: "Headache and mild fever",
    cardMedicationInfo: "Medication Info",
    cardMedicationDesc: "Side effects of Ibuprofen",
    cardWellnessTips: "Wellness Tips",
    cardWellnessDesc: "Improve sleep schedule",
    cardHealthMetrics: "Health Metrics",
    cardHealthDesc: "Normal blood pressure",
    cardNutrition: "Nutrition",
    cardNutritionDesc: "Healthy diet advice",
    cardMentalHealth: "Mental Health",
    cardMentalDesc: "Stress management",
    cardFitnessPlan: "Fitness Plan",
    cardFitnessDesc: "Home workout routines",
    cardFirstAid: "First Aid",
    cardFirstAidDesc: "Treating minor burns",
    cardVaccinations: "Vaccinations",
    cardVaccinationsDesc: "Adult immunization schedule",
    cardLabResults: "Lab Results",
    cardLabResultsDesc: "Understanding blood tests",
  },
  es: { 
    appTitle: "Gemma Health Edge",
    disclaimer_title: "Descargo de Responsabilidad Médica", 
    disclaimer_text: "Este asistente de salud de IA proporciona información solo con fines educativos...", 
    disclaimer_accept: "Entiendo", 
    settings_title: "Ajustes",
    status_checking: "Comprobando…",
    status_online: "En línea",
    status_offline: "Desconectado",
    input_placeholder: "Describa los síntomas...",
    welcome_title: "Gemma Health Edge",
    welcome_subtitle: "Panel de inteligencia médica avanzada fuera de línea",
    settings_thinking: "Mostrar pensamiento",
    toast_copied: "Copied!",
    toast_saved: "Saved!",
    toast_error: "Error occurred",
    thinking: "Thinking…",
    newSession: "New Session",
    serverOnline: "Online",
    serverOffline: "Offline",
    autoDetect: "Auto-detect",
    calendarTitle: "Health Calendar",
    moodLabel: "Mood",
    moodAverage: "Avg this month",
    cameraButton: "Camera",
    galleryButton: "Gallery",
    researchNote: "🔬 Wikipedia context added",
    notADoctor: "I'm not a doctor. Always consult a healthcare professional.",
    sessionHistory: "Session History",
    clearChat: "Clear",
    help: "Help",
    btn_clear_chat: "Clear",
    copyMessage: "Copy",
    exportChat: "Export Chat",
    privacyBadge: "100% Private",
    healthSector: "Health Sector",
    moodQuestion: "How are you feeling today?",
    moodNotePlaceholder: "Add a note (optional)...",
    medicalDisclaimer: "Medical Disclaimer",
    disclaimerText: "This assistant provides information only. It is not a substitute for professional medical advice, diagnosis, or treatment.",
    hwHardware: "Hardware",
    hwVRAM: "VRAM",
    hwAcceleration: "Acceleration",
    hwTTFT: "TTFT",
    hwTPS: "TPS",
    hwTotalTime: "TOTAL TIME",
    hwPrivacyMode: "Privacy Mode",
    hwPrivacyValue: "100% Offline",
    cardSymptomChecker: "Symptom Checker",
    cardSymptomDesc: "Headache and mild fever",
    cardMedicationInfo: "Medication Info",
    cardMedicationDesc: "Side effects of Ibuprofen",
    cardWellnessTips: "Wellness Tips",
    cardWellnessDesc: "Improve sleep schedule",
    cardHealthMetrics: "Health Metrics",
    cardHealthDesc: "Normal blood pressure",
    cardNutrition: "Nutrition",
    cardNutritionDesc: "Healthy diet advice",
    cardMentalHealth: "Mental Health",
    cardMentalDesc: "Stress management",
    cardFitnessPlan: "Fitness Plan",
    cardFitnessDesc: "Home workout routines",
    cardFirstAid: "First Aid",
    cardFirstAidDesc: "Treating minor burns",
    cardVaccinations: "Vaccinations",
    cardVaccinationsDesc: "Adult immunization schedule",
    cardLabResults: "Lab Results",
    cardLabResultsDesc: "Understanding blood tests",
  },
  zh: { 
    appTitle: "Gemma Health Edge",
    disclaimer_title: "医疗免责声明", 
    disclaimer_text: "此人工智能健康助手仅提供教育信息...", 
    disclaimer_accept: "我理解", 
    settings_title: "设置",
    status_checking: "正在检查…",
    status_online: "在线",
    status_offline: "离线",
    input_placeholder: "描述症状...",
    welcome_title: "Gemma Health Edge",
    welcome_subtitle: "高级离线医疗智能仪表板",
    settings_thinking: "显示思考过程",
    toast_copied: "Copied!",
    toast_saved: "Saved!",
    toast_error: "Error occurred",
    thinking: "Thinking…",
    newSession: "New Session",
    serverOnline: "Online",
    serverOffline: "Offline",
    autoDetect: "Auto-detect",
    calendarTitle: "Health Calendar",
    moodLabel: "Mood",
    moodAverage: "Avg this month",
    cameraButton: "Camera",
    galleryButton: "Gallery",
    researchNote: "🔬 Wikipedia context added",
    notADoctor: "I'm not a doctor. Always consult a healthcare professional.",
    sessionHistory: "Session History",
    clearChat: "Clear",
    help: "Help",
    btn_clear_chat: "Clear",
    copyMessage: "Copy",
    exportChat: "Export Chat",
    privacyBadge: "100% Private",
    healthSector: "Health Sector",
    moodQuestion: "How are you feeling today?",
    moodNotePlaceholder: "Add a note (optional)...",
    medicalDisclaimer: "Medical Disclaimer",
    disclaimerText: "This assistant provides information only. It is not a substitute for professional medical advice, diagnosis, or treatment.",
    hwHardware: "Hardware",
    hwVRAM: "VRAM",
    hwAcceleration: "Acceleration",
    hwTTFT: "TTFT",
    hwTPS: "TPS",
    hwTotalTime: "TOTAL TIME",
    hwPrivacyMode: "Privacy Mode",
    hwPrivacyValue: "100% Offline",
    cardSymptomChecker: "Symptom Checker",
    cardSymptomDesc: "Headache and mild fever",
    cardMedicationInfo: "Medication Info",
    cardMedicationDesc: "Side effects of Ibuprofen",
    cardWellnessTips: "Wellness Tips",
    cardWellnessDesc: "Improve sleep schedule",
    cardHealthMetrics: "Health Metrics",
    cardHealthDesc: "Normal blood pressure",
    cardNutrition: "Nutrition",
    cardNutritionDesc: "Healthy diet advice",
    cardMentalHealth: "Mental Health",
    cardMentalDesc: "Stress management",
    cardFitnessPlan: "Fitness Plan",
    cardFitnessDesc: "Home workout routines",
    cardFirstAid: "First Aid",
    cardFirstAidDesc: "Treating minor burns",
    cardVaccinations: "Vaccinations",
    cardVaccinationsDesc: "Adult immunization schedule",
    cardLabResults: "Lab Results",
    cardLabResultsDesc: "Understanding blood tests",
  },
  hi: { 
    appTitle: "Gemma Health Edge",
    disclaimer_title: "चिकित्सा अस्वीकरण", 
    disclaimer_text: "यह एआई स्वास्थ्य सहायक केवल शैक्षिक उद्देश्यों के लिए जानकारी प्रदान करता है...", 
    disclaimer_accept: "मैं समझता हूँ", 
    settings_title: "सेटिंग्स",
    status_checking: "जाँच हो रही है…",
    status_online: "ऑनलाइन",
    status_offline: "ऑफलाइन",
    input_placeholder: "लक्षणों का वर्णन करें...",
    welcome_title: "Gemma Health Edge",
    welcome_subtitle: "उन्नत ऑफ़लाइन चिकित्सा खुफिया डैशबोर्ड",
    settings_thinking: "सोच दिखाएं",
    toast_copied: "Copied!",
    toast_saved: "Saved!",
    toast_error: "Error occurred",
    thinking: "Thinking…",
    newSession: "New Session",
    serverOnline: "Online",
    serverOffline: "Offline",
    autoDetect: "Auto-detect",
    calendarTitle: "Health Calendar",
    moodLabel: "Mood",
    moodAverage: "Avg this month",
    cameraButton: "Camera",
    galleryButton: "Gallery",
    researchNote: "🔬 Wikipedia context added",
    notADoctor: "I'm not a doctor. Always consult a healthcare professional.",
    sessionHistory: "Session History",
    clearChat: "Clear",
    help: "Help",
    btn_clear_chat: "Clear",
    copyMessage: "Copy",
    exportChat: "Export Chat",
    privacyBadge: "100% Private",
    healthSector: "Health Sector",
    moodQuestion: "How are you feeling today?",
    moodNotePlaceholder: "Add a note (optional)...",
    medicalDisclaimer: "Medical Disclaimer",
    disclaimerText: "This assistant provides information only. It is not a substitute for professional medical advice, diagnosis, or treatment.",
    hwHardware: "Hardware",
    hwVRAM: "VRAM",
    hwAcceleration: "Acceleration",
    hwTTFT: "TTFT",
    hwTPS: "TPS",
    hwTotalTime: "TOTAL TIME",
    hwPrivacyMode: "Privacy Mode",
    hwPrivacyValue: "100% Offline",
    cardSymptomChecker: "Symptom Checker",
    cardSymptomDesc: "Headache and mild fever",
    cardMedicationInfo: "Medication Info",
    cardMedicationDesc: "Side effects of Ibuprofen",
    cardWellnessTips: "Wellness Tips",
    cardWellnessDesc: "Improve sleep schedule",
    cardHealthMetrics: "Health Metrics",
    cardHealthDesc: "Normal blood pressure",
    cardNutrition: "Nutrition",
    cardNutritionDesc: "Healthy diet advice",
    cardMentalHealth: "Mental Health",
    cardMentalDesc: "Stress management",
    cardFitnessPlan: "Fitness Plan",
    cardFitnessDesc: "Home workout routines",
    cardFirstAid: "First Aid",
    cardFirstAidDesc: "Treating minor burns",
    cardVaccinations: "Vaccinations",
    cardVaccinationsDesc: "Adult immunization schedule",
    cardLabResults: "Lab Results",
    cardLabResultsDesc: "Understanding blood tests",
  },
  ru: { 
    appTitle: "Gemma Health Edge",
    disclaimer_title: "Отказ от медицинской ответственности", 
    disclaimer_text: "Этот медицинский ИИ-помощник предоставляет информацию только в образовательных целях...", 
    disclaimer_accept: "Я понимаю", 
    settings_title: "Настройки",
    status_checking: "Проверка…",
    status_online: "В сети",
    status_offline: "Не в сети",
    input_placeholder: "Опишите симптомы...",
    welcome_title: "Gemma Health Edge",
    welcome_subtitle: "Продвинутая оффлайн-панель медицинского интеллекта",
    settings_thinking: "Показать процесс мышления",
    toast_copied: "Copied!",
    toast_saved: "Saved!",
    toast_error: "Error occurred",
    thinking: "Thinking…",
    newSession: "New Session",
    serverOnline: "Online",
    serverOffline: "Offline",
    autoDetect: "Auto-detect",
    calendarTitle: "Health Calendar",
    moodLabel: "Mood",
    moodAverage: "Avg this month",
    cameraButton: "Camera",
    galleryButton: "Gallery",
    researchNote: "🔬 Wikipedia context added",
    notADoctor: "I'm not a doctor. Always consult a healthcare professional.",
    sessionHistory: "Session History",
    clearChat: "Clear",
    help: "Help",
    btn_clear_chat: "Clear",
    copyMessage: "Copy",
    exportChat: "Export Chat",
    privacyBadge: "100% Private",
    healthSector: "Health Sector",
    moodQuestion: "How are you feeling today?",
    moodNotePlaceholder: "Add a note (optional)...",
    medicalDisclaimer: "Medical Disclaimer",
    disclaimerText: "This assistant provides information only. It is not a substitute for professional medical advice, diagnosis, or treatment.",
    hwHardware: "Hardware",
    hwVRAM: "VRAM",
    hwAcceleration: "Acceleration",
    hwTTFT: "TTFT",
    hwTPS: "TPS",
    hwTotalTime: "TOTAL TIME",
    hwPrivacyMode: "Privacy Mode",
    hwPrivacyValue: "100% Offline",
    cardSymptomChecker: "Symptom Checker",
    cardSymptomDesc: "Headache and mild fever",
    cardMedicationInfo: "Medication Info",
    cardMedicationDesc: "Side effects of Ibuprofen",
    cardWellnessTips: "Wellness Tips",
    cardWellnessDesc: "Improve sleep schedule",
    cardHealthMetrics: "Health Metrics",
    cardHealthDesc: "Normal blood pressure",
    cardNutrition: "Nutrition",
    cardNutritionDesc: "Healthy diet advice",
    cardMentalHealth: "Mental Health",
    cardMentalDesc: "Stress management",
    cardFitnessPlan: "Fitness Plan",
    cardFitnessDesc: "Home workout routines",
    cardFirstAid: "First Aid",
    cardFirstAidDesc: "Treating minor burns",
    cardVaccinations: "Vaccinations",
    cardVaccinationsDesc: "Adult immunization schedule",
    cardLabResults: "Lab Results",
    cardLabResultsDesc: "Understanding blood tests",
  },
  mn: { 
    appTitle: "Gemma Health Edge",
    disclaimer_title: "Эмнэлгийн хариуцлагын татгалзал", 
    disclaimer_text: "Энэхүү AI эрүүл мэндийн туслаг зөвхөн боловсролын зорилгоор мэдээлэл өгдөг...", 
    disclaimer_accept: "Ойлголоо", 
    settings_title: "Тохиргоо",
    status_checking: "Шалгаж байна…",
    status_online: "Онлайн",
    status_offline: "Оффлайн",
    input_placeholder: "Шинж тэмдгийг тайлбарлах...",
    welcome_title: "Gemma Health Edge",
    welcome_subtitle: "Дэвшилтэй офлайн эмнэлгийн ухаалагийн самбар",
    settings_thinking: "Бодол харуулах",
    toast_copied: "Copied!",
    toast_saved: "Saved!",
    toast_error: "Error occurred",
    thinking: "Thinking…",
    newSession: "New Session",
    serverOnline: "Online",
    serverOffline: "Offline",
    autoDetect: "Auto-detect",
    calendarTitle: "Health Calendar",
    moodLabel: "Mood",
    moodAverage: "Avg this month",
    cameraButton: "Camera",
    galleryButton: "Gallery",
    researchNote: "🔬 Wikipedia context added",
    notADoctor: "I'm not a doctor. Always consult a healthcare professional.",
    sessionHistory: "Session History",
    clearChat: "Clear",
    help: "Help",
    btn_clear_chat: "Clear",
    copyMessage: "Copy",
    exportChat: "Export Chat",
    privacyBadge: "100% Private",
    healthSector: "Health Sector",
    moodQuestion: "How are you feeling today?",
    moodNotePlaceholder: "Add a note (optional)...",
    medicalDisclaimer: "Medical Disclaimer",
    disclaimerText: "This assistant provides information only. It is not a substitute for professional medical advice, diagnosis, or treatment.",
    hwHardware: "Hardware",
    hwVRAM: "VRAM",
    hwAcceleration: "Acceleration",
    hwTTFT: "TTFT",
    hwTPS: "TPS",
    hwTotalTime: "TOTAL TIME",
    hwPrivacyMode: "Privacy Mode",
    hwPrivacyValue: "100% Offline",
    cardSymptomChecker: "Symptom Checker",
    cardSymptomDesc: "Headache and mild fever",
    cardMedicationInfo: "Medication Info",
    cardMedicationDesc: "Side effects of Ibuprofen",
    cardWellnessTips: "Wellness Tips",
    cardWellnessDesc: "Improve sleep schedule",
    cardHealthMetrics: "Health Metrics",
    cardHealthDesc: "Normal blood pressure",
    cardNutrition: "Nutrition",
    cardNutritionDesc: "Healthy diet advice",
    cardMentalHealth: "Mental Health",
    cardMentalDesc: "Stress management",
    cardFitnessPlan: "Fitness Plan",
    cardFitnessDesc: "Home workout routines",
    cardFirstAid: "First Aid",
    cardFirstAidDesc: "Treating minor burns",
    cardVaccinations: "Vaccinations",
    cardVaccinationsDesc: "Adult immunization schedule",
    cardLabResults: "Lab Results",
    cardLabResultsDesc: "Understanding blood tests",
  },
  ja: { 
    appTitle: "Gemma Health Edge",
    disclaimer_title: "免責事項", 
    disclaimer_text: "このAIヘルスアシスタントは教育目的の情報のみを提供します...", 
    disclaimer_accept: "理解しました", 
    settings_title: "設定",
    status_checking: "確認中…",
    status_online: "オンライン",
    status_offline: "オフライン",
    input_placeholder: "症状を説明してください...",
    welcome_title: "Gemma Health Edge",
    welcome_subtitle: "高度なオフライン医療インテリジェンスダッシュボード",
    settings_thinking: "思考を表示",
    toast_copied: "Copied!",
    toast_saved: "Saved!",
    toast_error: "Error occurred",
    thinking: "Thinking…",
    newSession: "New Session",
    serverOnline: "Online",
    serverOffline: "Offline",
    autoDetect: "Auto-detect",
    calendarTitle: "Health Calendar",
    moodLabel: "Mood",
    moodAverage: "Avg this month",
    cameraButton: "Camera",
    galleryButton: "Gallery",
    researchNote: "🔬 Wikipedia context added",
    notADoctor: "I'm not a doctor. Always consult a healthcare professional.",
    sessionHistory: "Session History",
    clearChat: "Clear",
    help: "Help",
    btn_clear_chat: "Clear",
    copyMessage: "Copy",
    exportChat: "Export Chat",
    privacyBadge: "100% Private",
    healthSector: "Health Sector",
    moodQuestion: "How are you feeling today?",
    moodNotePlaceholder: "Add a note (optional)...",
    medicalDisclaimer: "Medical Disclaimer",
    disclaimerText: "This assistant provides information only. It is not a substitute for professional medical advice, diagnosis, or treatment.",
    hwHardware: "Hardware",
    hwVRAM: "VRAM",
    hwAcceleration: "Acceleration",
    hwTTFT: "TTFT",
    hwTPS: "TPS",
    hwTotalTime: "TOTAL TIME",
    hwPrivacyMode: "Privacy Mode",
    hwPrivacyValue: "100% Offline",
    cardSymptomChecker: "Symptom Checker",
    cardSymptomDesc: "Headache and mild fever",
    cardMedicationInfo: "Medication Info",
    cardMedicationDesc: "Side effects of Ibuprofen",
    cardWellnessTips: "Wellness Tips",
    cardWellnessDesc: "Improve sleep schedule",
    cardHealthMetrics: "Health Metrics",
    cardHealthDesc: "Normal blood pressure",
    cardNutrition: "Nutrition",
    cardNutritionDesc: "Healthy diet advice",
    cardMentalHealth: "Mental Health",
    cardMentalDesc: "Stress management",
    cardFitnessPlan: "Fitness Plan",
    cardFitnessDesc: "Home workout routines",
    cardFirstAid: "First Aid",
    cardFirstAidDesc: "Treating minor burns",
    cardVaccinations: "Vaccinations",
    cardVaccinationsDesc: "Adult immunization schedule",
    cardLabResults: "Lab Results",
    cardLabResultsDesc: "Understanding blood tests",
  },
  ko: { 
    appTitle: "Gemma Health Edge",
    disclaimer_title: "의료 면책 조항", 
    disclaimer_text: "이 AI 건강 도우미는 교육 목적으로만 정보를 제공합니다...", 
    disclaimer_accept: "이해함", 
    settings_title: "설정",
    status_checking: "확인 중…",
    status_online: "온라인",
    status_offline: "오프라인",
    input_placeholder: "증상을 설명하세요...",
    welcome_title: "Gemma Health Edge",
    welcome_subtitle: "고급 오프라인 의료 인텔리전스 대시보드",
    settings_thinking: "思考を表示",
    toast_copied: "Copied!",
    toast_saved: "Saved!",
    toast_error: "Error occurred",
    thinking: "Thinking…",
    newSession: "New Session",
    serverOnline: "Online",
    serverOffline: "Offline",
    autoDetect: "Auto-detect",
    calendarTitle: "Health Calendar",
    moodLabel: "Mood",
    moodAverage: "Avg this month",
    cameraButton: "Camera",
    galleryButton: "Gallery",
    researchNote: "🔬 Wikipedia context added",
    notADoctor: "I'm not a doctor. Always consult a healthcare professional.",
    sessionHistory: "Session History",
    clearChat: "Clear",
    help: "Help",
    btn_clear_chat: "Clear",
    copyMessage: "Copy",
    exportChat: "Export Chat",
    privacyBadge: "100% Private",
    healthSector: "Health Sector",
    moodQuestion: "How are you feeling today?",
    moodNotePlaceholder: "Add a note (optional)...",
    medicalDisclaimer: "Medical Disclaimer",
    disclaimerText: "This assistant provides information only. It is not a substitute for professional medical advice, diagnosis, or treatment.",
    hwHardware: "Hardware",
    hwVRAM: "VRAM",
    hwAcceleration: "Acceleration",
    hwTTFT: "TTFT",
    hwTPS: "TPS",
    hwTotalTime: "TOTAL TIME",
    hwPrivacyMode: "Privacy Mode",
    hwPrivacyValue: "100% Offline",
    cardSymptomChecker: "Symptom Checker",
    cardSymptomDesc: "Headache and mild fever",
    cardMedicationInfo: "Medication Info",
    cardMedicationDesc: "Side effects of Ibuprofen",
    cardWellnessTips: "Wellness Tips",
    cardWellnessDesc: "Improve sleep schedule",
    cardHealthMetrics: "Health Metrics",
    cardHealthDesc: "Normal blood pressure",
    cardNutrition: "Nutrition",
    cardNutritionDesc: "Healthy diet advice",
    cardMentalHealth: "Mental Health",
    cardMentalDesc: "Stress management",
    cardFitnessPlan: "Fitness Plan",
    cardFitnessDesc: "Home workout routines",
    cardFirstAid: "First Aid",
    cardFirstAidDesc: "Treating minor burns",
    cardVaccinations: "Vaccinations",
    cardVaccinationsDesc: "Adult immunization schedule",
    cardLabResults: "Lab Results",
    cardLabResultsDesc: "Understanding blood tests",
  }
};

const SUPPORTED_LANGS = Object.keys(dictionary);
const t = (key, lang = 'en') => (dictionary[lang] || dictionary.en)[key] || dictionary.en[key] || key;
const i18n = (lang) => ({ t: (key) => t(key, lang) });

// ── Persistence ──────────────────────────────────────────────────────────────

const Storage = {
  get: (key, defaultValue = null) => { 
    try { 
      const item = localStorage.getItem(key); 
      return item ? JSON.parse(item) : defaultValue; 
    } catch (e) { 
      console.error('[Storage] Get failed:', e); 
      return defaultValue; 
    } 
  },
  set: (key, value) => { 
    try { 
      localStorage.setItem(key, JSON.stringify(value)); 
      return true; 
    } catch (e) { 
      console.error('[Storage] Set failed:', e); 
      return false; 
    } 
  },
  remove: (key) => localStorage.removeItem(key),
  clear: () => localStorage.clear(),
};

// ── Configuration ────────────────────────────────────────────────────────────

const DEFAULT_CONFIG = {
  apiMode: 'local', 
  middlemanUrl: 'http://127.0.0.1:8080', 
  theme: 'dark', 
  lang: 'en',
  showThinking: true, 
  researchMode: true,
  cameraEnabled: false, 
  voiceEnabled: false,
  accentColor1: '#4285f4', 
  accentColor2: '#8b5cf6', 
  accentColor3: '#ec4899',
};

const Config = {
  get: (key) => { 
    const cfg = Storage.get('config', {}); 
    return cfg[key] !== undefined ? cfg[key] : DEFAULT_CONFIG[key]; 
  },
  set: (key, value) => {
    const cfg = Storage.get('config', {}); 
    cfg[key] = value; 
    return Storage.set('config', cfg);
  },
  getAll: () => ({ ...DEFAULT_CONFIG, ...Storage.get('config', {}) }),
  reset: () => Storage.set('config', {}),
};

// ── API Helpers ──────────────────────────────────────────────────────────────

const getAPIBase = () => Config.get('middlemanUrl') || 'http://127.0.0.1:8080';

const apiFetch = async (endpoint, options = {}) => {
  const url = `${getAPIBase()}${endpoint}`;
  try {
    const response = await fetch(url, {
      ...options,
      headers: { 'Content-Type': 'application/json', ...options.headers },
    });
    return { ok: response.ok, status: response.status, data: response.ok ? await response.json() : null };
  } catch (e) {
    console.error(`[API] Fetch failed for ${endpoint}:`, e);
    return { ok: false, error: e };
  }
};

const ChatStorage = {
  getSessions: () => apiFetch('/api/v1/data/sessions').then(r => r.data || []),
  getSession: (id) => apiFetch(`/api/v1/data/sessions/${id}`).then(r => r.data),
  deleteSession: (id) => apiFetch(`/api/v1/data/sessions/${id}`, { method: 'DELETE' }).then(r => r.ok),
  saveSession: async (session) => {
    return apiFetch(`/api/v1/data/sessions/${session.id}`, { method: 'PUT', body: JSON.stringify(session) }).then(r => r.ok);
  },
  clear: async () => {
    const sessions = await ChatStorage.getSessions();
    for (const s of sessions) await ChatStorage.deleteSession(s.id);
  }
};

const ClinicalProfile = {
  get: () => apiFetch('/api/v1/data/profile').then(r => r.data || {}),
  save: (data) => apiFetch('/api/v1/data/profile', { method: 'POST', body: JSON.stringify(data) }).then(r => r.ok),
  clear: () => ClinicalProfile.save({}),
};

const MoodTracker = {
  getHistory: (year, month) => apiFetch(`/api/v1/data/moods?year=${year}&month=${month}`).then(r => r.data || { history: {} }),
  saveMood: (date, mood, note = '') => apiFetch('/api/v1/data/moods', { method: 'POST', body: JSON.stringify({ date, mood, note }) }).then(r => r.ok),
};

const copyToClipboard = async (text) => {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch (e) {
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed'; ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    document.execCommand('copy');
    document.body.removeChild(ta);
    return true;
  }
};

// ── Utilities ────────────────────────────────────────────────────────────

const generateId = () => Date.now().toString(36) + Math.random().toString(36).substr(2, 5);

const showToast = (message, type = 'info') => {
  const existing = document.querySelector('.toast-notification');
  if (existing) existing.remove();
  
  const toast = document.createElement('div');
  toast.className = `toast-notification toast-${type}`;
  toast.textContent = message;
  document.body.appendChild(toast);
  
  setTimeout(() => {
    toast.classList.add('fade-out');
    setTimeout(() => toast.remove(), 300);
  }, 3000);
};

async function detectGPU() {
  const info = { gpu: 'Unknown', vram: 'Unknown', accel: 'CPU', npu: null };
  if (!navigator.gpu) return info;
  try {
    const adapter = await navigator.gpu.requestAdapter();
    if (adapter) {
      const adapterInfo = await adapter.requestAdapterInfo();
      info.gpu = adapterInfo.description || adapterInfo.vendor || 'WebGPU Device';
      info.accel = 'WebGPU';
      if (adapterInfo.memory) info.vram = `${(adapterInfo.memory / 1024 / 1024 / 1024).toFixed(1)} GB`;
    }
  } catch (e) {
    console.debug('[Hardware] WebGPU detection bypassed.');
  }
  return info;
}

const resizeImage = (file, max = 512) => {
  return new Promise((resolve) => {
    const img = new Image();
    img.onload = () => {
      let { width: w, height: h } = img;
      if (w > max || h > max) {
        const r = Math.min(max / w, max / h);
        w *= r; h *= r;
      }
      const canvas = document.createElement('canvas');
      canvas.width = w; canvas.height = h;
      canvas.getContext('2d').drawImage(img, 0, 0, w, h);
      canvas.toBlob(blob => {
        const reader = new FileReader();
        reader.onloadend = () => resolve(reader.result);
        reader.readAsDataURL(blob);
      }, 'image/jpeg', 0.85);
    };
    img.src = URL.createObjectURL(file);
  });
};

const sanitizeHTML = (str) => {
  if (!str) return '';
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
};

const formatMarkdown = (text) => {
  if (!text) return '';
  return sanitizeHTML(text)
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.+?)\*/g, '<em>$1</em>')
    .replace(/`(.+?)`/g, '<code>$1</code>')
    .replace(/\n/g, '<br>');
};

// ── Exports ──────────────────────────────────────────────────────────────────

window.GHE = window.GHE || {};
window.GHE.Core = {
  t, i18n, SUPPORTED_LANGS, dictionary,
  Storage, Config, DEFAULT_CONFIG,
  ChatStorage, ClinicalProfile, MoodTracker,
  generateId, showToast, detectGPU, resizeImage,
  sanitizeHTML, formatMarkdown, getAPIBase,
  copyToClipboard
};
window.Core = window.GHE.Core;
