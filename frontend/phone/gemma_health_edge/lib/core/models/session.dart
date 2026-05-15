import 'message.dart';

/// Chat session stored in Hive.
/// Max sessions stored: 10 (rolling — delete oldest when exceeded)
class Session {
  final String id;
  final String title;
  final DateTime date;
  final List<Message> messages;

  static const int maxSessions = 10;

  const Session({
    required this.id,
    required this.title,
    required this.date,
    required this.messages,
  });

  Session copyWith({
    String? id,
    String? title,
    DateTime? date,
    List<Message>? messages,
  }) {
    return Session(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? [];
    final messages = rawMessages
        .whereType<Map<String, dynamic>>()
        .map((m) => Message.fromJson(m))
        .toList();

    return Session(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      messages: messages,
    );
  }

  /// Whether this session is valid (has at least one message)
  bool get isValid => messages.isNotEmpty;

  /// Enforce rolling window: keeps only the newest [maxSessions] sessions
  static List<Session> enforceLimit(List<Session> sessions) {
    if (sessions.length <= maxSessions) return sessions;
    // Sort by date descending and take only the newest
    final sorted = List<Session>.from(sessions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(maxSessions).toList();
  }

  @override
  String toString() =>
      'Session(id: $id, title: $title, messages: ${messages.length})';
}
