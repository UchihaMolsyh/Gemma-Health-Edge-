import 'dart:convert';
import 'dart:io';

void main() {
  final dir = Directory('lib/core/i18n');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb'));
  
  for (final file in files) {
    try {
      final content = file.readAsStringSync();
      final Map<String, dynamic> data = jsonDecode(content);
      
      bool changed = false;
      if (!data.containsKey('exportChat')) {
        data['exportChat'] = 'Export Chat';
        changed = true;
      }
      if (!data.containsKey('privacyBadge')) {
        data['privacyBadge'] = '100% Private';
        changed = true;
      }
      
      if (changed) {
        file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
        print('Updated ${file.path}');
      }
    } catch (e) {
      print('Error processing ${file.path}: $e');
    }
  }
}
