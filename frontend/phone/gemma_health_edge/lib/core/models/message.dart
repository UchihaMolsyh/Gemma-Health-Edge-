/// Chat message model stored in Hive.
/// Roles: 'user', 'assistant', 'system'
class Message {
  final String id;
  final String role;
  final String content;
  final String? imageBase64;
  final DateTime timestamp;
  final String? severity;
  final bool unvalidated;

  const Message({
    required this.id,
    required this.role,
    required this.content,
    this.imageBase64,
    required this.timestamp,
    this.severity,
    this.unvalidated = false,
  });

  Message copyWith({
    String? id,
    String? role,
    String? content,
    String? imageBase64,
    DateTime? timestamp,
    String? severity,
    bool? unvalidated,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      imageBase64: imageBase64 ?? this.imageBase64,
      timestamp: timestamp ?? this.timestamp,
      severity: severity ?? this.severity,
      unvalidated: unvalidated ?? this.unvalidated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'imageBase64': imageBase64,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity,
      'unvalidated': unvalidated,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      imageBase64: json['imageBase64'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      severity: json['severity'] as String?,
      unvalidated: json['unvalidated'] as bool? ?? false,
    );
  }

  /// Build the API payload for /v1/chat/completions
  Map<String, dynamic> toApiMessage() {
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      final textContent =
          content.trim().isEmpty ? 'Describe this image.' : content;
      return {
        'role': role,
        'content': [
          {'type': 'text', 'text': textContent},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'}
          }
        ],
      };
    }
    return {'role': role, 'content': content};
  }

  @override
  String toString() =>
      'Message(role: $role, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
}
