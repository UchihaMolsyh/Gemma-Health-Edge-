import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/mood_entry.dart';
import '../../core/storage_service.dart';
import '../chat/chat_provider.dart';

// ─── Calendar State ─────────────────────────────────────────────────────────

class CalendarState {
  final DateTime displayedMonth;
  final Map<String, MoodEntry> moods; // key: 'YYYY-MM-DD'
  final bool isLoading;

  const CalendarState({
    required this.displayedMonth,
    this.moods = const {},
    this.isLoading = false,
  });

  CalendarState copyWith({
    DateTime? displayedMonth,
    Map<String, MoodEntry>? moods,
    bool? isLoading,
  }) {
    return CalendarState(
      displayedMonth: displayedMonth ?? this.displayedMonth,
      moods: moods ?? this.moods,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Calculate monthly average mood.
  double? get monthlyAverage {
    final monthStr =
        '${displayedMonth.year}-${displayedMonth.month.toString().padLeft(2, '0')}';
    final monthMoods = moods.entries
        .where((e) => e.key.startsWith(monthStr))
        .map((e) => e.value.mood)
        .toList();
    if (monthMoods.isEmpty) return null;
    return monthMoods.reduce((a, b) => a + b) / monthMoods.length;
  }

  /// Get mood emoji for average.
  String? get averageEmoji {
    final avg = monthlyAverage;
    if (avg == null) return null;
    final rounded = avg.round().clamp(1, 5);
    return MoodEntry.emojiMap[rounded];
  }
}

// ─── Calendar Notifier ──────────────────────────────────────────────────────

class CalendarNotifier extends Notifier<CalendarState> {
  late final StorageService _storage;

  @override
  CalendarState build() {
    _storage = ref.read(storageServiceProvider);
    // Defer mood loading to avoid state updates during build phase
    Future.microtask(() => _loadMoods());
    return CalendarState(displayedMonth: DateTime.now());
  }

  void _loadMoods() {
    final entries = _storage.loadMoods();
    final map = <String, MoodEntry>{};
    for (final entry in entries) {
      if (entry.isValid) {
        map[entry.date] = entry;
      }
    }
    state = state.copyWith(moods: map);
  }

  Future<void> setMood(String date, int mood) async {
    if (mood < 1 || mood > 5) return;

    final entry = MoodEntry(date: date, mood: mood);
    await _storage.saveMood(entry);

    final moods = Map<String, MoodEntry>.from(state.moods);
    moods[date] = entry;
    state = state.copyWith(moods: moods);
  }

  Future<void> clearMood(String date) async {
    await _storage.deleteMood(date);

    final moods = Map<String, MoodEntry>.from(state.moods);
    moods.remove(date);
    state = state.copyWith(moods: moods);
  }

  void previousMonth() {
    final current = state.displayedMonth;
    state = state.copyWith(
      displayedMonth: DateTime(current.year, current.month - 1, 1),
    );
  }

  void nextMonth() {
    final current = state.displayedMonth;
    state = state.copyWith(
      displayedMonth: DateTime(current.year, current.month + 1, 1),
    );
  }

  void goToToday() {
    state = state.copyWith(displayedMonth: DateTime.now());
  }
}

// ─── Provider ───────────────────────────────────────────────────────────────

final calendarProvider = NotifierProvider<CalendarNotifier, CalendarState>(CalendarNotifier.new);
