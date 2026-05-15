/// Gemma Health Edge — Instant Greeting Recognition Service
/// Detects simple greetings and returns instant responses without AI processing.
class GreetingService {
  // Common greetings in multiple languages (68 patterns)
  static const Set<String> _greetingPatterns = {
    // English
    'hello', 'hi', 'hey', 'greetings', 'good morning', 'good afternoon',
    'good evening',
    'good day', "what's up", 'howdy', 'yo', 'sup', 'how are you',
    'how do you do',
    // Spanish
    'hola', 'buenos dias', 'buenas tardes', 'buenas noches', 'que tal',
    'como estas',
    // French
    'bonjour', 'bonsoir', 'salut', 'ca va', 'comment allez-vous',
    // German
    'guten tag', 'guten morgen', 'guten abend', 'hallo', "wie geht's",
    // Italian
    'ciao', 'buongiorno', 'buonasera', 'come stai',
    // Portuguese
    'ola', 'bom dia', 'boa tarde', 'boa noite', 'como vai',
    // Chinese
    'ni hao', 'zao shang hao', 'wan shang hao', 'nin hao',
    // Japanese
    'konnichiwa', 'ohayou', 'konbanwa', 'moshi moshi',
    // Korean
    'annyeong', 'annyeonghaseyo', 'jal jinesseoyo',
    // Russian
    'privet', 'zdravstvuyte', 'dobroe utro', 'dobryy den', 'dobryy vecher',
    // Hindi
    'namaste', 'namaskar', 'kaise ho', 'suprabhat',
    // Arabic
    'marhaba', 'as-salamu alaykum', 'sabah al-khair', 'masa al-khair',
    // Other
    'shalom', 'salam', 'jambo', 'sawubona', 'merhaba',
  };

  // Medical keywords that disqualify a greeting
  static const Set<String> _medicalKeywords = {
    'pain',
    'symptom',
    'doctor',
    'medicine',
    'headache',
    'fever',
    'cough',
    'disease',
    'sick',
    'hurt',
    'injury',
    'prescription',
    'treatment',
    'diagnosis',
    'health',
    'medical',
    'hospital',
    'clinic',
    'drug',
    'pill',
    'medication',
    'allergy',
    'vaccine',
    'virus',
    'infection',
    'nurse',
    'patient',
    'therapy',
    'surgery',
    'emergency',
    'urgent',
    'dizzy',
    'nausea',
    'vomit',
    'rash',
    'wound',
    'bleeding',
    'fracture',
    'broken',
    'swelling',
    'inflammation',
    'cancer',
    'diabetes',
    'stroke',
    'heart',
    'liver',
    'kidney',
    'lung',
    'brain',
    'bone',
    'muscle',
  };

  static final List<String> _greetingResponses = [
    "Hello! Welcome to Gemma Health Edge. I'm here to provide health information and support. How can I help you today?",
    "Hi there! I'm your health assistant. I can answer questions about symptoms, nutrition, mental health, and more. What would you like to know?",
    "Welcome! I'm Gemma, your private health AI. Remember, I'm here to provide information—not medical advice. What's on your mind?",
    "Good day! I'm ready to help with your health questions. Whether it's about diet, exercise, symptoms, or general wellness, feel free to ask!",
    "Hello! I'm here to support your health journey. While I can provide helpful information, please consult a healthcare professional for medical decisions. What can I assist with?",
  ];

  /// Check if text is a simple greeting (no medical content)
  static bool isGreeting(String text) {
    if (text.isEmpty) return false;

    final textLower = text.toLowerCase().trim();
    final textClean = textLower.replaceAll(RegExp(r'[.!?,:;]'), '').trim();

    // First check: if any medical keyword is present, it's NOT a pure greeting
    final words = textLower.split(RegExp(r'\s+'));
    for (final word in words) {
      if (_medicalKeywords.contains(word)) {
        return false;
      }
    }

    // Check for exact match
    if (_greetingPatterns.contains(textClean)) {
      return true;
    }

    // Check if starts with a greeting pattern
    for (final greeting in _greetingPatterns) {
      if (textClean.startsWith('$greeting ') ||
          textClean.startsWith('$greeting,')) {
        final remainder = textClean.substring(greeting.length).trim();

        // Empty remainder = pure greeting
        if (remainder.isEmpty) return true;

        // Check remainder word count
        final remainderWords = remainder.split(RegExp(r'\s+'));
        if (remainderWords.length <= 3) {
          // Additional check: verify remainder doesn't contain medical keywords
          for (final word in remainderWords) {
            if (_medicalKeywords.contains(word)) {
              return false;
            }
          }
          return true;
        }
      }
    }

    // Single word short greetings (fallback)
    if (textClean.split(RegExp(r'\s+')).length == 1 && textClean.length <= 10) {
      return _greetingPatterns.contains(textClean);
    }

    return false;
  }

  /// Get a random greeting response
  static String getGreetingResponse() {
    final index = DateTime.now().millisecond % _greetingResponses.length;
    return _greetingResponses[index];
  }

  /// Get all supported languages count
  static int get supportedLanguagesCount => _greetingPatterns.length;
}
