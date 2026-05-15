import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_health_edge/core/models/message.dart';

void main() {
  group('Message model', () {
    test('toJson/fromJson roundtrip', () {
      final msg = Message(
        id: '1',
        role: 'user',
        content: 'hello world',
        imageBase64: 'abc123',
        timestamp: DateTime(2020, 1, 2, 3, 4, 5),
      );

      final json = msg.toJson();
      final restored = Message.fromJson(json);

      expect(restored.id, equals(msg.id));
      expect(restored.role, equals(msg.role));
      expect(restored.content, equals(msg.content));
      expect(restored.imageBase64, equals(msg.imageBase64));
      expect(restored.timestamp.toUtc(), equals(msg.timestamp.toUtc()));
    });

    test('toApiMessage with image', () {
      final msg = Message(
        id: '1',
        role: 'user',
        content: 'Describe this image',
        imageBase64: 'abcdef',
        timestamp: DateTime.now(),
      );

      final api = msg.toApiMessage();
      expect(api['role'], 'user');
      expect(api['content'], isA<List>());
      final parts = api['content'] as List;
      expect(parts.length, greaterThanOrEqualTo(2));
      expect(parts[0]['type'], 'text');
      expect(parts[0]['text'], contains('Describe this image'));
      expect(parts[1]['type'], 'image_url');
      final imageUrl = parts[1]['image_url'] as Map<String, dynamic>;
      expect(imageUrl['url'], 'data:image/jpeg;base64,abcdef');
    });
  });
}
