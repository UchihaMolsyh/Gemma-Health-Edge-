/// Gemma Health Edge — Instant Emergency Interceptor
/// Detects emergency medical situations and instantly returns a crisis card.
class EmergencyService {
  static const Set<String> _emergencyTerms = {
    'heart attack',
    'cardiac arrest',
    'chest pain',
    'pressure in chest',
    'stroke',
    'face droop',
    'slurred speech',
    'can\'t breathe',
    'cannot breathe',
    'not breathing',
    'shortness of breath',
    'suicide',
    'suicidal',
    'kill myself',
    'end my life',
    'want to die',
    'overdose',
    'took too many pills',
    'drank poison',
    'swallowed poison',
    'bleeding out',
    'severe bleeding',
    'unconscious',
    'fainting',
    'seizure',
    'anaphylaxis',
    'throat closing',
    'allergic reaction',
  };

  /// Check if text contains any emergency phrases
  static bool isEmergency(String text) {
    if (text.isEmpty) return false;
    final lowerText = text.toLowerCase();

    for (final term in _emergencyTerms) {
      if (lowerText.contains(term)) {
        return true;
      }
    }
    return false;
  }

  /// Get region-aware emergency numbers
  static String getEmergencyResponse() {
    // Basic locale mapping based on dart:io Platform if possible,
    // or just a comprehensive list. We'll provide a global list.
    return '''🚨 **CALL EMERGENCY SERVICES NOW** 🚨

It sounds like you may be experiencing a medical emergency. 

Please stop using this app and call for help immediately:
- 🇺🇸 USA / Canada: **911**
- 🇬🇧 UK: **999**
- 🇪🇺 European Union: **112**
- 🇦🇺 Australia: **000**
- 🇳🇿 New Zealand: **111**
- 🇯🇵 Japan: **119**
- 🇰🇷 South Korea: **119**
- 🇨🇳 China: **120**
- 🇮🇳 India: **112** (or 102/108)

If you are experiencing a mental health crisis or having suicidal thoughts:
- 🇺🇸 USA: **988** (Suicide & Crisis Lifeline)
- 🇬🇧 UK: **111** (or 999 in emergency)
- 🌍 International: Please go to the nearest emergency room.

**Do not wait. Seek professional medical help immediately.**''';
  }
}
