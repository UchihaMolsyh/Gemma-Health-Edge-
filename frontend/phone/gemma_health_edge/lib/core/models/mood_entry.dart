import 'package:flutter/material.dart';

/// Health calendar mood entry stored in Hive.
/// Mood scale: 1=Poor, 2=Fair, 3=Okay, 4=Good, 5=Great
class MoodEntry {
  final String date; // 'YYYY-MM-DD'
  final int mood; // 1-5

  static const List<String?> emojiMap = [null, '😔', '😐', '🙂', '😊', '😁'];

  static const List<Color?> colorMap = [
    null,
    Color(0xFFEF4444), // 1 - Poor (red)
    Color(0xFFF59E0B), // 2 - Fair (amber)
    Color(0xFF3B82F6), // 3 - Okay (blue)
    Color(0xFF10B981), // 4 - Good (green)
    Color(0xFF8B5CF6), // 5 - Great (purple)
  ];

  static const List<String?> labelMap = [
    null,
    'Poor',
    'Fair',
    'Okay',
    'Good',
    'Great'
  ];

  const MoodEntry({
    required this.date,
    required this.mood,
  });

  /// Validate mood is within 1-5 range
  bool get isValid => mood >= 1 && mood <= 5;

  String? get emoji => (mood >= 1 && mood <= 5) ? emojiMap[mood] : null;
  Color? get color => (mood >= 1 && mood <= 5) ? colorMap[mood] : null;
  String? get label => (mood >= 1 && mood <= 5) ? labelMap[mood] : null;

  MoodEntry copyWith({String? date, int? mood}) {
    return MoodEntry(
      date: date ?? this.date,
      mood: mood ?? this.mood,
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'mood': mood};
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      date: json['date'] as String? ?? '',
      mood: (json['mood'] as num?)?.toInt() ?? 3,
    );
  }

  @override
  String toString() => 'MoodEntry(date: $date, mood: $mood $emoji)';
}
