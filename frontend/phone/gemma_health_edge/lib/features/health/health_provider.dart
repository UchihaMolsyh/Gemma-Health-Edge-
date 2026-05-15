import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/health_service.dart';
import '../../core/models/health_sample.dart';
import '../../core/storage_service.dart';
import '../chat/chat_provider.dart';

class HealthState {
  final bool isAuthorized;
  final bool isLoading;
  final String? error;
  final List<HealthSample> samples;

  const HealthState({
    this.isAuthorized = false,
    this.isLoading = false,
    this.error,
    this.samples = const [],
  });

  HealthState copyWith({
    bool? isAuthorized,
    bool? isLoading,
    String? error,
    List<HealthSample>? samples,
  }) {
    return HealthState(
      isAuthorized: isAuthorized ?? this.isAuthorized,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      samples: samples ?? this.samples,
    );
  }
}

class HealthNotifier extends Notifier<HealthState> {
  late final HealthService _health;
  late final StorageService _storage;

  @override
  HealthState build() {
    _health = ref.read(healthServiceProvider);
    _storage = ref.read(storageServiceProvider);
    // Defer sample loading to avoid state updates during build phase
    final samples = _storage.loadHealthSamples();
    Future.microtask(() => state = state.copyWith(samples: samples));
    return const HealthState();
  }

  Future<void> requestPermissions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ok = await _health.requestAuthorization();
      state = state.copyWith(isAuthorized: ok, isLoading: false);
      if (ok) {
        await refresh();
      }
    } catch (e) {
      state = state.copyWith(
        isAuthorized: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    if (!state.isAuthorized) return;

    state = state.copyWith(isLoading: true, error: null);
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 7));

    try {
      final fetched = await _health.fetchSamples(start: start, end: end);
      await _storage.saveHealthSamples(fetched);
      final merged = _storage.loadHealthSamples();
      state = state.copyWith(samples: merged, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService();
});

final healthProvider = NotifierProvider<HealthNotifier, HealthState>(HealthNotifier.new);
