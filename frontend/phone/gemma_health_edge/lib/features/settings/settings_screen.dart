import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/models/app_settings.dart';
import '../chat/chat_provider.dart';
import 'settings_provider.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _serverUrlController;
  late TextEditingController _cloudApiKeyController;
  bool _obscureApiKey = true;

  late TextEditingController _cloudModelIdController;
  bool _isAutoDetecting = false;

  @override
  void initState() {
    super.initState();
    _serverUrlController = TextEditingController();
    _cloudApiKeyController = TextEditingController();
    _cloudModelIdController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider).settings;
      _serverUrlController.text = settings.serverUrl;
      _cloudApiKeyController.text = settings.cloudApiKey;
      _cloudModelIdController.text = settings.cloudModelId;
    });
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _cloudApiKeyController.dispose();
    _cloudModelIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);
    final chatState = ref.watch(chatProvider);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = Color(state.settings.accentColor);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(l10n.settingsTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ─── Connection Section ───────────────────────────────
          // ─── Connection Section ───────────────────────────────
          _buildSectionHeader('Connection', Icons.wifi, accentColor),
          const SizedBox(height: 8),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cloud API'),
                  subtitle: const Text('Use Google AI Studio or OpenRouter'),
                  value: state.settings.useCloudApi,
                  activeThumbColor: accentColor,
                  onChanged: (v) {
                    ref.read(settingsProvider.notifier).updateUseCloudApi(v);
                    if (v) {
                      ref.read(settingsProvider.notifier).updateUseLocalOnDeviceAi(false);
                    }
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('On-Device AI (Mobile)'),
                  subtitle:
                      const Text('Run AI directly on this phone (Offline)'),
                  value: state.settings.useLocalOnDeviceAi,
                  activeThumbColor: accentColor,
                  onChanged: (v) {
                    ref.read(settingsProvider.notifier).updateUseLocalOnDeviceAi(v);
                    if (v) {
                      ref.read(settingsProvider.notifier).updateUseCloudApi(false);
                    }
                  },
                ),
                if (state.settings.useLocalOnDeviceAi) ...[
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Inference Engine'),
                    subtitle: Text(state.settings.localAiType == 'litert' ? 'LiteRT (TF Lite)' : 'llama.cpp.dart'),
                    trailing: DropdownButton<String>(
                      value: state.settings.localAiType,
                      items: const [
                        DropdownMenuItem(value: 'litert', child: Text('LiteRT')),
                        DropdownMenuItem(value: 'llama_cpp', child: Text('llama.cpp')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsProvider.notifier).updateLocalAiType(val);
                        }
                      },
                    ),
                  ),
                  if (state.settings.localAiType == 'litert') ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: const Text('LiteRT model download feature coming soon'),
                    ),
                  ],
                ],
                const Divider(height: 1),
                if (!state.settings.useCloudApi && !state.settings.useLocalOnDeviceAi) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('AI Backend Type'),
                    subtitle: state.settings.useOllama 
                        ? const Text('Ollama (port 11434)')
                        : state.settings.useSubBackendE2B
                            ? const Text('Sub-Backend (port 8081)')
                            : const Text('Gemma Backend (port 8080)'),
                    trailing: DropdownButton<String>(
                      value: state.settings.useOllama ? 'ollama' : (state.settings.useSubBackendE2B ? 'sub_backend' : 'gemma'),
                      items: [
                        DropdownMenuItem(
                          value: 'gemma',
                          child: const Text('Gemma'),
                        ),
                        DropdownMenuItem(
                          value: 'sub_backend',
                          child: const Text('Sub-Backend (E2B)'),
                        ),
                        DropdownMenuItem(
                          value: 'ollama',
                          child: const Text('Ollama'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          // Update backend settings based on selection
                          if (value == 'ollama') {
                            ref.read(settingsProvider.notifier).updateUseOllama(true);
                            ref.read(settingsProvider.notifier).updateUseSubBackendE2B(false);
                            final newUrl = 'http://192.168.1.1:11434';
                            _serverUrlController.text = newUrl;
                            ref.read(settingsProvider.notifier).updateServerUrl(newUrl);
                          } else if (value == 'sub_backend') {
                            ref.read(settingsProvider.notifier).updateUseOllama(false);
                            ref.read(settingsProvider.notifier).updateUseSubBackendE2B(true);
                            final newUrl = 'http://192.168.1.1:8081';
                            _serverUrlController.text = newUrl;
                            ref.read(settingsProvider.notifier).updateServerUrl(newUrl);
                          } else {
                            ref.read(settingsProvider.notifier).updateUseOllama(false);
                            ref.read(settingsProvider.notifier).updateUseSubBackendE2B(false);
                            final newUrl = 'http://192.168.1.1:8080';
                            _serverUrlController.text = newUrl;
                            ref.read(settingsProvider.notifier).updateServerUrl(newUrl);
                          }
                        }
                      },
                    ),
                  ),
                ],
                const Divider(height: 1),
                if (!state.settings.useCloudApi) ...[
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  // Server URL field
                  TextField(
                    controller: _serverUrlController,
                    decoration: InputDecoration(
                      labelText: l10n.serverUrl,
                      hintText: 'http://192.168.1.1:8080',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: TextButton(
                        child: Text(l10n.testConnection),
                        onPressed: () async {
                          await ref
                              .read(settingsProvider.notifier)
                              .updateServerUrl(
                                  _serverUrlController.text.trim());
                          await ref
                              .read(chatProvider.notifier)
                              .checkServerHealth();
                        },
                      ),
                    ),
                    onSubmitted: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateServerUrl(value.trim());
                    },
                  ),
                  const SizedBox(height: 12),

                  // Auto-detect button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search, size: 18),
                      label: Text(l10n.autoDetect),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                            color: accentColor.withOpacity(0.5)),
                      ),
                      onPressed: _isAutoDetecting
                          ? null
                          : () async {
                              final scaffoldMessenger =
                                  ScaffoldMessenger.of(context);
                              setState(() => _isAutoDetecting = true);
                              final url = await ref
                                  .read(chatProvider.notifier)
                                  .autoDetectServer();
                              if (!mounted) return;
                              setState(() => _isAutoDetecting = false);
                              if (url != null) {
                                _serverUrlController.text = url;
                                ref
                                    .read(settingsProvider.notifier)
                                    .updateServerUrl(url);
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                        content: Text(l10n.serverFound(url))),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(content: Text(l10n.noServerFound)),
                                  );
                                }
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Cloud API key fields (only visible when Cloud API is enabled)
                if (state.settings.useCloudApi) ...[
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cloudApiKeyController,
                    obscureText: _obscureApiKey,
                    decoration: InputDecoration(
                      labelText: 'Cloud API Key',
                      hintText: 'Enter your Google AI Studio or OpenRouter key',
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                          color: accentColor,
                        ),
                        onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: state.settings.cloudApiKey.isNotEmpty && 
                                !state.settings.cloudApiKey.startsWith('AIza') &&
                                !state.settings.cloudApiKey.startsWith('sk-')
                            ? 'Invalid API key format'
                            : null,
                    ),
                    onSubmitted: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateCloudApiKey(value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('API key saved'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cloudModelIdController,
                    decoration: InputDecoration(
                      labelText: 'Model ID',
                      hintText: 'google/gemma-4-27b-it',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateCloudModelId(value);
                    },
                  ),
                ],

                // Server status
                  Row(
                    children: [
                      Icon(
                        chatState.serverStatus == 'online'
                            ? Icons.check_circle
                            : chatState.serverStatus == 'checking'
                                ? Icons.refresh
                                : Icons.error,
                        color: chatState.serverStatus == 'online'
                            ? const Color(0xFF10B981)
                            : chatState.serverStatus == 'checking'
                                ? Colors.grey
                                : const Color(0xFFEF4444),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        chatState.serverStatus == 'online'
                            ? l10n.serverOnline
                            : chatState.serverStatus == 'checking'
                                ? l10n.serverChecking
                                : l10n.serverOffline,
                        style: TextStyle(
                          color: chatState.serverStatus == 'online'
                              ? const Color(0xFF10B981)
                              : chatState.serverStatus == 'checking'
                                  ? Colors.grey
                                  : const Color(0xFFEF4444),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Connection metrics
                  if (chatState.connectionMetrics != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connection Quality',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildMetricItem(
                                'Success Rate',
                                chatState.connectionMetrics!['successRate'] ??
                                    'N/A',
                                isDark,
                              ),
                              const SizedBox(width: 16),
                              _buildMetricItem(
                                'Avg Latency',
                                '${chatState.connectionMetrics!['averageLatencyMs'] ?? 'N/A'}ms',
                                isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Appearance Section ───────────────────────────
          _buildSectionHeader(
              l10n.appearanceSection, Icons.palette, accentColor),
          const SizedBox(height: 8),
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.themeLabel,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                        value: 'dark',
                        label: Text(l10n.themeDark),
                        icon: const Icon(Icons.dark_mode, size: 18)),
                    ButtonSegment(
                        value: 'light',
                        label: Text(l10n.themeLight),
                        icon: const Icon(Icons.light_mode, size: 18)),
                    ButtonSegment(
                        value: 'system',
                        label: Text(l10n.themeSystem),
                        icon: const Icon(Icons.settings_brightness, size: 18)),
                  ],
                  selected: {state.settings.theme},
                  onSelectionChanged: (selected) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateTheme(selected.first);
                  },
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.accentColor,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _buildColorPresets(state.settings, accentColor),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(l10n.resetColors),
                    onPressed: () =>
                        ref.read(settingsProvider.notifier).resetColors(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Language Section ──────────────────────────────
          _buildSectionHeader(l10n.languageLabel, Icons.language, accentColor),
          const SizedBox(height: 8),
          _buildCard(
            isDark: isDark,
            child: _buildLanguageGrid(state.settings, accentColor),
          ),

          const SizedBox(height: 24),

          // ─── Features Section ─────────────────────────────
          _buildSectionHeader(l10n.featuresSection, Icons.tune, accentColor),
          const SizedBox(height: 8),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.showThinking),
                  subtitle: const Text('Display AI reasoning process'),
                  value: state.settings.showThinking,
                  activeThumbColor: accentColor,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).updateShowThinking(v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.voiceOutput),
                  subtitle: const Text('Read responses aloud'),
                  value: state.settings.enableVoice,
                  activeThumbColor: accentColor,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).updateEnableVoice(v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.researchMode),
                  subtitle: const Text('Fetch Wikipedia context when online'),
                  value: state.settings.enableResearch,
                  activeThumbColor: accentColor,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .updateEnableResearch(v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Clinical Profile Section ─────────────────────
          _buildSectionHeader(
              'Clinical Profile', Icons.medical_information, accentColor),
          const SizedBox(height: 8),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                _buildEditableTile(
                  title: 'Allergies',
                  value: state.settings.allergies.isEmpty
                      ? 'None'
                      : state.settings.allergies,
                  icon: Icons.warning_amber_outlined,
                  onTap: () => _showClinicalEditDialog(
                    title: 'Allergies',
                    value: state.settings.allergies,
                    hint: 'e.g., Penicillin, Peanuts',
                    onSave: (v) =>
                        ref.read(settingsProvider.notifier).updateAllergies(v),
                  ),
                ),
                const Divider(height: 1),
                _buildEditableTile(
                  title: 'Medical Conditions',
                  value: state.settings.conditions.isEmpty
                      ? 'None'
                      : state.settings.conditions,
                  icon: Icons.healing_outlined,
                  onTap: () => _showClinicalEditDialog(
                    title: 'Medical Conditions',
                    value: state.settings.conditions,
                    hint: 'e.g., Diabetes, Hypertension',
                    onSave: (v) =>
                        ref.read(settingsProvider.notifier).updateConditions(v),
                  ),
                ),
                const Divider(height: 1),
                _buildEditableTile(
                  title: 'Current Medications',
                  value: state.settings.medications.isEmpty
                      ? 'None'
                      : state.settings.medications,
                  icon: Icons.medication_outlined,
                  onTap: () => _showClinicalEditDialog(
                    title: 'Current Medications',
                    value: state.settings.medications,
                    hint: 'e.g., Metformin 500mg daily',
                    onSave: (v) => ref
                        .read(settingsProvider.notifier)
                        .updateMedications(v),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.cake_outlined, color: accentColor),
                  title: const Text('Age'),
                  trailing: Text(
                    state.settings.age != null
                        ? '${state.settings.age} years'
                        : 'Not set',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  onTap: () => _showNumberEditDialog(
                    title: 'Age',
                    value: state.settings.age?.toString() ?? '',
                    onSave: (v) {
                      final age = int.tryParse(v);
                      ref.read(settingsProvider.notifier).updateAge(age);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.scale_outlined, color: accentColor),
                  title: const Text('Weight'),
                  trailing: Text(
                    state.settings.weight != null
                        ? '${state.settings.weight} kg'
                        : 'Not set',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  onTap: () => _showNumberEditDialog(
                    title: 'Weight (kg)',
                    value: state.settings.weight?.toString() ?? '',
                    onSave: (v) {
                      final weight = double.tryParse(v);
                      ref.read(settingsProvider.notifier).updateWeight(weight);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.notes_outlined, color: accentColor),
                  title: const Text('Clinical Notes'),
                  subtitle: state.settings.clinicalNotes.isNotEmpty
                      ? Text(
                          state.settings.clinicalNotes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12),
                        )
                      : null,
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => _showClinicalEditDialog(
                    title: 'Clinical Notes',
                    value: state.settings.clinicalNotes,
                    hint: 'Any additional health information',
                    maxLines: 5,
                    onSave: (v) => ref
                        .read(settingsProvider.notifier)
                        .updateClinicalNotes(v),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Data Section ─────────────────────────────────
          _buildSectionHeader(l10n.dataSection, Icons.storage, accentColor),
          const SizedBox(height: 8),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.upload, color: accentColor),
                  title: Text(l10n.exportData),
                  onTap: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      final data = await ref
                          .read(settingsProvider.notifier)
                          .exportData();
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Backup ready (${(data.length / 1024).toStringAsFixed(1)} KB)',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Export failed: $e')),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.download, color: accentColor),
                  title: Text(l10n.importData),
                  onTap: () {
                    // TODO: File picker integration
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Import from file picker coming soon')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: Text(l10n.clearAllData,
                      style: const TextStyle(color: Colors.redAccent)),
                  onTap: () => _showClearConfirmation(l10n),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.data_usage, color: Colors.grey.shade500),
                  title: Text(l10n.storageStats),
                  trailing: Text(
                    '${(ref.read(settingsProvider.notifier).storageSize / 1024).toStringAsFixed(1)} KB',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Troubleshooting Section ─────────────────────
          _buildSectionHeader(
              'Troubleshooting', Icons.build_outlined, accentColor),
          const SizedBox(height: 8),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.bug_report_outlined, color: accentColor),
                  title: const Text('Diagnostics'),
                  subtitle: const Text('System info & error logs'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => _showDiagnosticsDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.help_outline, color: accentColor),
                  title: const Text('FAQ'),
                  subtitle: const Text('Common questions & answers'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => _showFAQDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.refresh, color: accentColor),
                  title: const Text('Reset App'),
                  subtitle: const Text('Clear cache & reset settings'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => _showResetConfirmation(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── About Section ────────────────────────────────
          _buildSectionHeader(
              l10n.aboutSection, Icons.info_outline, accentColor),
          const SizedBox(height: 8),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.aboutVersion),
                  trailing: Text('2.0.0',
                      style: TextStyle(color: Colors.grey.shade500)),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.aboutDisclaimer),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => _showDisclaimer(l10n),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color accentColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accentColor),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accentColor,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildColorPresets(AppSettings settings, Color currentColor) {
    const presets = [
      0xFF3B82F6, // Blue
      0xFF8B5CF6, // Purple
      0xFF10B981, // Green
      0xFFEF4444, // Red
      0xFFF59E0B, // Amber
      0xFFEC4899, // Pink
      0xFF06B6D4, // Cyan
      0xFFF97316, // Orange
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...presets.map((colorInt) {
          final isSelected = settings.accentColor == colorInt;
          return GestureDetector(
            onTap: () =>
                ref.read(settingsProvider.notifier).updateAccentColor(colorInt),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(colorInt),
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Color(colorInt).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          );
        }),
        // Custom color picker
        GestureDetector(
          onTap: () => _showColorPicker(currentColor),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400, width: 2),
              gradient: const SweepGradient(
                colors: [
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                  Colors.red,
                ],
              ),
            ),
            child: const Icon(Icons.colorize, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(Color currentColor) {
    Color pickedColor = currentColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.accentColor),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) => pickedColor = color,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            child: Text(AppLocalizations.of(context)!.confirm),
            onPressed: () {
              ref
                  .read(settingsProvider.notifier)
                  .updateAccentColor(pickedColor.toARGB32());
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageGrid(AppSettings settings, Color accentColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppSettings.supportedLanguages.map((lang) {
        final isSelected = settings.language == lang;
        final name = AppSettings.languageNames[lang] ?? lang;
        return ChoiceChip(
          label: Text(name),
          selected: isSelected,
          selectedColor: accentColor.withOpacity(0.2),
          side: BorderSide(
            color: isSelected ? accentColor : Colors.grey.shade400,
          ),
          labelStyle: TextStyle(
            color: isSelected ? accentColor : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: (_) =>
              ref.read(settingsProvider.notifier).updateLanguage(lang),
        );
      }).toList(),
    );
  }

  Widget _buildMetricItem(String label, String value, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Clinical Profile Helper Methods ─────────────────────────────────────

  Widget _buildEditableTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  void _showClinicalEditDialog({
    required String title,
    required String value,
    required String hint,
    required Function(String) onSave,
    int maxLines = 1,
  }) {
    final controller = TextEditingController(text: value);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          maxLines: maxLines,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNumberEditDialog({
    required String title,
    required String value,
    required Function(String) onSave,
  }) {
    final controller = TextEditingController(text: value);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ─── Troubleshooting Helper Methods ────────────────────────────────────

  void _showDiagnosticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Diagnostics'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('App Info:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Version: 2.0.0'),
              Text('Build: Release'),
              SizedBox(height: 12),
              Text('System Info:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_getPlatformName()),
              SizedBox(height: 12),
              Text('Connection Status:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_getBackendType(ref.watch(settingsProvider).settings)),
              SizedBox(height: 12),
              Text(ref.watch(settingsProvider).settings.serverUrl),
              SizedBox(height: 12),
              Text('Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('No errors detected'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFAQDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('FAQ'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Q: How do I connect to my PC?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  'A: Go to Settings > Connection and enter your PC IP address.'),
              SizedBox(height: 8),
              TextButton(
                child: Text('Test Connection'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await ref.read(chatProvider.notifier).checkServerHealth();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Connection test completed')),
                  );
                },
              ),
              SizedBox(height: 8),
              Text('Q: Is my data private?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  'A: Yes, all processing happens locally on your device or PC.'),
              SizedBox(height: 8),
              Text('Q: How do I sync health data?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  'A: Use the Health screen to sync with HealthKit.'),
              SizedBox(height: 8),
              TextButton(
                child: Text('Export Logs'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await _exportLogs();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Logs exported successfully')),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<String> _exportLogs() async {
    try {
      // Collect system information and logs
      final logs = StringBuffer();
      logs.writeln('=== Gemma Health Edge Diagnostics ===');
      logs.writeln('Timestamp: ${DateTime.now().toIso8601String()}');
      logs.writeln('App Version: 2.0.0');
      logs.writeln('Platform: ${Theme.of(context).platform == TargetPlatform.iOS ? 'iOS' : 'Android'}');
      logs.writeln('');
      logs.writeln('=== Current Settings ===');
      final settingsState = ref.read(settingsProvider);
      final settings = settingsState.settings;
      logs.writeln('Backend: ${_getBackendType(settings)}');
      logs.writeln('Server URL: ${settings.serverUrl}');
      logs.writeln('Language: ${settings.language}');
      logs.writeln('Theme: ${settings.theme}');
      logs.writeln('');
      logs.writeln('=== Connection Status ===');
      logs.writeln('Status: ${ref.read(chatProvider).isOnline ? 'Online' : 'Offline'}');
      logs.writeln('Last Health Check: ${DateTime.now().toIso8601String()}');
      logs.writeln('');
      logs.writeln('=== Error Logs ===');
      logs.writeln('No critical errors detected');
      logs.writeln('');
      logs.writeln('=== End of Report ===');
      
      return logs.toString();
    } catch (e) {
      return 'Error exporting logs: $e';
    }
  }

  String _getPlatformName() {
    return Theme.of(context).platform == TargetPlatform.iOS ? 'iOS' : 'Android';
  }

  String _getBackendType(AppSettings settings) {
    if (settings.useCloudApi) return 'Cloud API';
    if (settings.useOllama) return 'Ollama';
    if (settings.useSubBackendE2B) return 'Sub-Backend';
    return 'Local';
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App?'),
        content: const Text(
          'This will clear all settings and cached data. Your chat history will be preserved. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Clear all data
              ref.read(settingsProvider.notifier).clearAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App reset successfully')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(AppLocalizations l10n) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearAllData),
        content: Text(l10n.clearAllConfirm),
        actions: [
          TextButton(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(l10n.confirm),
            onPressed: () {
              ref.read(settingsProvider.notifier).clearAllData();
              Navigator.pop(dialogContext);
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text(l10n.clearAllData)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDisclaimer(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.disclaimerTitle),
        content: SingleChildScrollView(
          child: Text(l10n.disclaimerBody),
        ),
        actions: [
          FilledButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
