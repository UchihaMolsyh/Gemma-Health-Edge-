import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/litert_provider.dart';

class LiteRTDownloadButton extends ConsumerWidget {
  const LiteRTDownloadButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(litertProvider);
    final notifier = ref.read(litertProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LiteRT Model',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        if (state.isInitialized)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Model loaded: ${state.currentConfig?.modelPath.split('/').last ?? 'Unknown'}',
                    style: TextStyle(color: Colors.green[700], fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else if (state.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(height: 8),
                  Text('Downloading model...', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await notifier.downloadGemma4LiteRT();
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Download Gemma 4 LiteRT Model'),
            ),
          ),
        if (state.error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.error!,
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
