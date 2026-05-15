import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import 'models/health_sample.dart';

class HealthService {
  final Health _health;

  HealthService({Health? health}) : _health = health ?? Health();

  static const List<HealthDataType> supportedTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  ];

  Future<bool> requestAuthorization() async {
    final permissions = supportedTypes
        .map((_) => HealthDataAccess.READ)
        .toList(growable: false);

    return _health.requestAuthorization(supportedTypes,
        permissions: permissions);
  }

  Future<List<HealthSample>> fetchSamples({
    required DateTime start,
    required DateTime end,
  }) async {
    // Validate date range
    if (start.isAfter(end)) {
      debugPrint('HealthService: Invalid date range - start is after end');
      return [];
    }

    // Limit date range to prevent excessive data fetch
    final maxDays = 365;
    final daysDiff = end.difference(start).inDays;
    if (daysDiff > maxDays) {
      debugPrint(
          'HealthService: Date range too large ($daysDiff days), limiting to $maxDays days');
      start = end.subtract(Duration(days: maxDays));
    }

    try {
      final points = await _health.getHealthDataFromTypes(
        types: supportedTypes,
        startTime: start,
        endTime: end,
      );

      final cleaned = _health.removeDuplicates(points);

      final out = <HealthSample>[];
      for (final p in cleaned) {
        final type = p.typeString;
        if (type == null || type.isEmpty) continue;

        final ts = p.dateFrom;
        if (ts == null) continue;

        final value = _extractNumericValue(p.value);
        if (value == null || value.isNaN) continue;

        // Validate value ranges for health data
        if (value < 0 || value > 100000) {
          // Reasonable upper bound
          continue;
        }

        final unit = _unitForType(p.type);
        final source = p.sourceName ?? 'Unknown';
        final id =
            _stableId(type: type, timestamp: ts, value: value, source: source);

        out.add(HealthSample(
          id: id,
          type: type,
          value: value,
          unit: unit,
          timestamp: ts,
          source: source,
        ));
      }

      // Limit results to prevent memory issues
      if (out.length > 5000) {
        debugPrint(
            'HealthService: Too many samples (${out.length}), limiting to 5000');
        out.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return out.sublist(0, 5000);
      }

      out.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return out;
    } catch (e, stackTrace) {
      debugPrint('HealthService: Failed to fetch samples: $e\n$stackTrace');
      return [];
    }
  }

  double? _extractNumericValue(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      final doubleVal = value.toDouble();
      // Check for special values
      if (doubleVal.isInfinite || doubleVal.isNaN) return null;
      return doubleVal;
    }

    try {
      final dynamic v = value;
      final dynamic numericValue = v.numericValue;
      if (numericValue is num) {
        final doubleVal = numericValue.toDouble();
        if (doubleVal.isInfinite || doubleVal.isNaN) return null;
        return doubleVal;
      }
    } catch (_) {
      // ignore
    }

    try {
      final strValue = value.toString();
      if (strValue.isEmpty) return null;
      final parsed = double.tryParse(strValue);
      if (parsed != null && (parsed.isInfinite || parsed.isNaN)) return null;
      return parsed;
    } catch (_) {
      return null;
    }
  }

  String _unitForType(HealthDataType type) {
    switch (type) {
      case HealthDataType.HEART_RATE:
        return 'bpm';
      case HealthDataType.BLOOD_OXYGEN:
        return '%';
      case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
      case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        return 'mmHg';
      default:
        return '';
    }
  }

  String _stableId({
    required String type,
    required DateTime timestamp,
    required double value,
    required String source,
  }) {
    // Sanitize inputs to prevent hash collisions
    final sanitizedType = type.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final sanitizedSource = source.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

    final ms = timestamp.millisecondsSinceEpoch;
    final scaled = (value * 1000).round();
    final h = _fnv1a32('$sanitizedType|$ms|$scaled|$sanitizedSource');
    return 'h_$h';
  }

  String _fnv1a32(String input) {
    const int fnvPrime = 0x01000193;
    int hash = 0x811C9DC5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
