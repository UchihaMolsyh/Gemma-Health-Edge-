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
    disclaimer_title: "⚠️ CRITICAL: Medical Disclaimer & Legal Notice", 
    disclaimer_text: "ARTIFICIAL INTELLIGENCE IS NOT A DOCTOR\n\n🚨 EMERGENCY: If experiencing chest pain, difficulty breathing, severe injury, thoughts of self-harm, or any life-threatening emergency, CALL 911 (US) or your local emergency number IMMEDIATELY. Do not use this app.\n\n⚖️ LEGAL BINDING NOTICE:\nThis application provides general health information ONLY. It is NOT a substitute for, and does NOT replace, professional medical advice, diagnosis, physical examination, or treatment by a licensed healthcare provider.\n\nWARNINGS:\n• NO WARRANTY: This application is provided "as-is" with NO guarantees of accuracy, completeness, or fitness for any medical purpose\n• NEVER rely on this AI for diagnosis, treatment decisions, or medication advice\n• AI may produce incorrect, incomplete, or dangerous medical information\n• Your medical history, context, and individual factors cannot be fully assessed by AI\n• Delaying professional medical care due to AI advice can result in serious harm or death\n\nYOU ARE RESPONSIBLE FOR:\n• Verifying all information with a licensed healthcare provider\n• Seeking immediate professional medical attention for any health concern\n• Disclosing all symptoms, medications, and medical history to your doctor\n• Understanding that self-diagnosis via AI is unreliable and potentially dangerous\n\nWe strongly recommend consulting with a licensed physician, nurse, or qualified healthcare professional for ANY medical concern. Your health and life depend on professional medical judgment." 
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
    medicalDisclaimer: "⚠️ MEDICAL DISCLAIMER",
    disclaimerText: "ARTIFICIAL INTELLIGENCE IS NOT A DOCTOR. This assistant provides general information only and is NOT a substitute for professional medical advice, diagnosis, or treatment. Always consult a licensed healthcare provider. In emergencies, call 911 immediately.",
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
    disclaimer_title: "⚠️ AVERTISSEMENT MÉDICAL CRITIQUE", 
    disclaimer_text: "L'INTELLIGENCE ARTIFICIELLE N'EST PAS UN MÉDECIN\n\n🚨 URGENCE: En cas de douleur thoracique, difficultés respiratoires, blessure grave, idées suicidaires ou urgence menaçant la vie, APPELEZ LE 15 (SAMU) ou vos services d'urgence IMMÉDIATEMENT.\n\n⚖️ AVIS JURIDIQUE CONTRAIGNANT:\nCette application fournit UNIQUEMENT des informations de santé générales. Elle ne remplace PAS les conseils, le diagnostic ou le traitement d'un professionnel de santé agréé.\n\nAVERTISSEMENTS:\n• AUCUNE GARANTIE: Cette application est fournie "telle quelle" sans garantie d'exactitude ou d'adéquation\n• Ne vous fiez JAMAIS à cette IA pour diagnostiquer, traiter ou prescrire\n• L'IA peut produire des informations médicales incorrectes ou dangereuses\n• Votre historique médical ne peut pas être pleinement évalué par l'IA\n• Retarder les soins médicaux professionnels peut avoir des conséquences graves ou mortelles\n\nVous êtes RESPONSABLE de:\n• Vérifier toute information auprès d'un professionnel de santé agréé\n• Consulter immédiatement un médecin pour toute préoccupation de santé\n• Révéler tous vos symptômes et antécédents médicaux à votre médecin\n\nConsultez toujours un médecin agréé pour tout problème de santé." 
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
    medicalDisclaimer: "⚠️ AVERTISSEMENT MÉDICAL",
    disclaimerText: "L'INTELLIGENCE ARTIFICIELLE N'EST PAS UN MÉDECIN. Cet assistant fournit uniquement des informations générales et ne remplace PAS l'avis médical professionnel, le diagnostic ou le traitement. Consultez toujours un professionnel de santé agréé. En cas d'urgence, appelez le 15 (SAMU) immédiatement.",
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
    disclaimer_title: "⚠️ KRITISCHER MEDIZINISCHER HAFTUNGSAUSSCHLUSS", 
    disclaimer_text: "KÜNSTLICHE INTELLIGENZ IST KEIN ARZT\n\n🚨 NOTFALL: Bei Brustschmerzen, Atemwegsbehinderung, schweren Verletzungen, Selbstmordgedanken oder lebensbedrohlichen Notfällen SOFORT den Rettungsdienst (112) anrufen. Diese App nicht verwenden.\n\n⚖️ RECHTLICHE BINDENDE MITTEILUNG:\nDiese Anwendung bietet NUR allgemeine Gesundheitsinformationen. Sie ersetzt NICHT die fachliche medizinische Beratung, Diagnose oder Behandlung durch einen lizenzierten Gesundheitsdienstleister.\n\nWARNUNGEN:\n• KEINE GARANTIE: Diese Anwendung wird „wie vorhanden" bereitgestellt OHNE Garantien für Genauigkeit oder medizinische Eignung\n• Verlassen Sie sich NIEMALS auf diese KI zur Diagnose, Behandlung oder Verschreibung\n• Die KI kann falsche oder gefährliche medizinische Informationen produzieren\n• Ihre medizinische Geschichte kann von der KI nicht vollständig bewertet werden\n• Das Verzögern professioneller medizinischer Versorgung kann schwerwiegende Folgen haben oder tödlich sein\n\nSIE SIND VERANTWORTLICH FÜR:\n• Überprüfung aller Informationen bei einem lizenzierten Gesundheitsdienstleister\n• Sofortige Konsultation eines Arztes für alle Gesundheitsbedenken\n• Offenlegung aller Symptome und medizinischen Vorgeschichte gegenüber Ihrem Arzt\n\nKonsultieren Sie immer einen lizenzierten Arzt für alle Gesundheitsprobleme.", 
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
    medicalDisclaimer: "⚠️ MEDIZINISCHER HAFTUNGSAUSSCHLUSS",
    disclaimerText: "KÜNSTLICHE INTELLIGENZ IST KEIN ARZT. Dieser Assistent bietet nur allgemeine Informationen und ist KEIN Ersatz für professionelle medizinische Beratung, Diagnose oder Behandlung. Konsultieren Sie immer einen lizenzierten Arzt. Rufen Sie im Notfall sofort 112 an.",
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
    disclaimer_title: "⚠️ DESCARGO CRÍTICO DE RESPONSABILIDAD MÉDICA", 
    disclaimer_text: "LA INTELIGENCIA ARTIFICIAL NO ES UN MÉDICO\n\n🚨 EMERGENCIA: Si experimenta dolor en el pecho, dificultad para respirar, lesiones graves, pensamientos suicidas o cualquier emergencia que amenace la vida, LLAME AL 911 (EE.UU.) o al número de emergencia local INMEDIATAMENTE.\n\n⚖️ AVISO LEGAL VINCULANTE:\nEsta aplicación proporciona SOLO información general de salud. NO reemplaza y NO sustituye el consejo médico profesional, el diagnóstico o el tratamiento de un proveedor de atención médica con licencia.\n\nADVERTENCIAS:\n• SIN GARANTÍA: Esta aplicación se proporciona \"tal cual\" SIN garantías de exactitud o idoneidad médica\n• NUNCA confíe en esta IA para diagnóstico, tratamiento o medicamentos\n• La IA puede producir información médica incorrecta o peligrosa\n• Su historial médico no puede ser evaluado completamente por la IA\n• Retrasar la atención médica profesional puede resultar en daño grave o muerte\n\nUSTE ES RESPONSABLE DE:\n• Verificar toda la información con un proveedor de atención médica con licencia\n• Buscar atención médica profesional inmediata para cualquier preocupación de salud\n• Divulgar todos los síntomas e historial médico a su médico\n\nSiempre consulte con un médico con licencia para cualquier problema de salud.", 
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
    medicalDisclaimer: "⚠️ DESCARGO DE RESPONSABILIDAD MÉDICA",
    disclaimerText: "LA INTELIGENCIA ARTIFICIAL NO ES UN MÉDICO. Este asistente proporciona solo información general y NO es un sustituto de la asesoramiento médico profesional, diagnóstico o tratamiento. Siempre consulte a un proveedor de atención médica con licencia. En emergencias, llame al 911 inmediatamente.",
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
