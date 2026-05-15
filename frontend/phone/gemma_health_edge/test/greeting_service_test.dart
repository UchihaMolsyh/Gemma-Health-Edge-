import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_health_edge/core/greeting_service.dart';

void main() {
  group('GreetingService', () {
    test('detects simple greetings', () {
      expect(GreetingService.isGreeting('hello'), isTrue);
      expect(GreetingService.isGreeting('hi'), isTrue);
      expect(GreetingService.isGreeting('hey'), isTrue);
    });

    test('detects multi-word greetings', () {
      expect(GreetingService.isGreeting('hi there'), isTrue);
      expect(GreetingService.isGreeting('hey, how are you'), isTrue);
      expect(GreetingService.isGreeting('good morning'), isTrue);
    });

    test('detects foreign language greetings', () {
      expect(GreetingService.isGreeting('hola'), isTrue);
      expect(GreetingService.isGreeting('bonjour'), isTrue);
      expect(GreetingService.isGreeting('konnichiwa'), isTrue);
      expect(GreetingService.isGreeting('namaste'), isTrue);
    });

    test('rejects greetings with medical content', () {
      expect(GreetingService.isGreeting('hi doctor'), isFalse);
      expect(GreetingService.isGreeting('hello, I have a headache'), isFalse);
      expect(GreetingService.isGreeting('hey I feel sick'), isFalse);
    });

    test('rejects non-greetings', () {
      expect(GreetingService.isGreeting('what is diabetes'), isFalse);
      expect(GreetingService.isGreeting('I have a fever'), isFalse);
      expect(GreetingService.isGreeting('prescribe me medicine'), isFalse);
    });

    test('returns non-empty greeting response', () {
      final response = GreetingService.getGreetingResponse();
      expect(response, isNotEmpty);
    });

    test('reports supported languages count', () {
      expect(GreetingService.supportedLanguagesCount, equals(68));
    });
  });
}
