import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_health_edge/core/rag_service.dart';

void main() {
  group('RagService', () {
    test('tokenize basic tokens with allowlist', () {
      final rag = RagService();
      final tokens = rag.tokenize('bp hr 4g xray unknown');
      // 'bp' and 'hr' are in allowlist; 'xray' and 'unknown' should be included (>3)
      expect(tokens.contains('bp'), isTrue);
      expect(tokens.contains('hr'), isTrue);
      expect(tokens.contains('xray'), isTrue);
      expect(tokens.contains('unknown'), isTrue);
    });

    test('init marks initialized (may load assets in test env)', () async {
      final rag = RagService();
      await rag.init();
      expect(rag.isInitialized, isTrue);
    });
  });
}
