import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/health_sample.dart';
import 'health_provider.dart';


class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(healthProvider);
    final notifier = ref.read(healthProvider.notifier);
    final theme = Theme.of(context);

    final hr = _latest(state.samples, type: 'HEART_RATE');
    final spo2 = _latest(state.samples, type: 'BLOOD_OXYGEN');
    final sys = _latest(state.samples, type: 'BLOOD_PRESSURE_SYSTOLIC');
    final dia = _latest(state.samples, type: 'BLOOD_PRESSURE_DIASTOLIC');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Metrics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: state.isLoading ? null : () => notifier.refresh(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(
            isAuthorized: state.isAuthorized,
            isLoading: state.isLoading,
            error: state.error,
            onRequest: () => notifier.requestPermissions(),
          ),
          const SizedBox(height: 12),
          _MetricCard(
            title: 'Heart rate',
            value: hr != null ? hr.value.toStringAsFixed(0) : '—',
            unit: hr?.unit ?? 'bpm',
            icon: Icons.favorite,
            subtitle: hr != null ? _meta(hr) : 'No data yet',
          ),
          const SizedBox(height: 12),
          _MetricCard(
            title: 'Blood oxygen (SpO₂)',
            value: spo2 != null ? spo2.value.toStringAsFixed(0) : '—',
            unit: spo2?.unit ?? '%',
            icon: Icons.bloodtype,
            subtitle: spo2 != null ? _meta(spo2) : 'No data yet',
          ),
          const SizedBox(height: 12),
          _MetricCard(
            title: 'Blood pressure',
            value: (sys != null && dia != null)
                ? '${sys.value.toStringAsFixed(0)}/${dia.value.toStringAsFixed(0)}'
                : '—',
            unit: 'mmHg',
            icon: Icons.monitor_heart,
            subtitle: (sys != null && dia != null)
                ? 'Latest • ${_formatTime(sys.timestamp)} • ${sys.source}'
                : 'No data yet',
          ),
          const SizedBox(height: 16),
          Text(
            'Stored samples: ${state.samples.length}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }



  HealthSample? _latest(List<HealthSample> samples, {required String type}) {
    for (final s in samples) {
      if (s.type == type) return s;
    }
    return null;
  }

  String _meta(HealthSample s) {
    return 'Latest • ${_formatTime(s.timestamp)} • ${s.source}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _HeaderCard extends StatelessWidget {
  final bool isAuthorized;
  final bool isLoading;
  final String? error;
  final VoidCallback onRequest;

  const _HeaderCard({
    required this.isAuthorized,
    required this.isLoading,
    required this.error,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.watch),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Connect health data',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This screen reads metrics provided by Apple Health / HealthKit (iOS) or Health Connect (Android).',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            if (error != null) ...[
              Text(
                error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                FilledButton.icon(
                  onPressed: isLoading ? null : onRequest,
                  icon: const Icon(Icons.lock_open),
                  label: Text(isAuthorized
                      ? 'Permissions granted'
                      : 'Grant permissions'),
                ),
                const SizedBox(width: 12),
                if (isLoading)
                  const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final String subtitle;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(unit, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
