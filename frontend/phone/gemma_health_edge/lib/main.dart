import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/i18n/app_localizations.dart';
import 'core/storage_service.dart';
import 'core/rag_service.dart';
import 'core/models/app_settings.dart';
import 'features/chat/chat_screen.dart';
import 'features/chat/chat_provider.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/settings_provider.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/health/health_screen.dart';
import 'core/inactivity_wrapper.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Gemma Health Edge - Main Entry Point
// 
// Initializes the Flutter app with:
// - Encrypted storage service (Hive + AES-256)
// - RAG (Retrieval-Augmented Generation) service for health data
// - Riverpod state management
// - Multi-language support
// - Theme and locale configuration
// ═════════════════════════════════════════════════════════════════════════════

void main() async {
  // Ensure Flutter bindings are initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('[Main] Initializing Gemma Health Edge...');

  // Initialize encrypted storage service (Hive with AES-256)
  final storageService = StorageService();
  await storageService.init();
  debugPrint('[Main] Storage service initialized');

  // Load saved user settings (theme, language, accent colors, etc.)
  final settings = await storageService.loadSettings();
  debugPrint('[Main] Settings loaded: ${settings.language}, ${settings.theme}');

  // Initialize RAG service in background (don't block UI startup)
  // RAG provides health context from nutrition datasets
  final ragService = RagService();
  ragService.init().catchError((e, stackTrace) {
    debugPrint('[Main] RAG init failed: $e\n$stackTrace');
  });

  debugPrint('[Main] Starting app...');

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        ragServiceProvider.overrideWithValue(ragService),
      ],
      child: GemmaHealthApp(initialSettings: settings),
    ),
  );
}

class GemmaHealthApp extends ConsumerWidget {
  final AppSettings initialSettings;

  const GemmaHealthApp({super.key, required this.initialSettings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final settings = settingsState.settings;
    final accentColor = Color(settings.accentColor);

    // Determine theme mode
    ThemeMode themeMode;
    switch (settings.theme) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'system':
        themeMode = ThemeMode.system;
        break;
      default:
        themeMode = ThemeMode.dark;
    }

    // Determine locale - ensure this is reactive to language changes
    Locale locale;
    switch (settings.language) {
      case 'fr':
        locale = const Locale('fr');
        break;
      case 'de':
        locale = const Locale('de');
        break;
      case 'es':
        locale = const Locale('es');
        break;
      case 'zh':
        locale = const Locale('zh');
        break;
      case 'hi':
        locale = const Locale('hi');
        break;
      case 'ru':
        locale = const Locale('ru');
        break;
      case 'ja':
        locale = const Locale('ja');
        break;
      case 'ko':
        locale = const Locale('ko');
        break;
      case 'mn':
        locale = const Locale('mn');
        break;
      default:
        locale = const Locale('en');
    }

    return InactivityWrapper(
        timeout: const Duration(minutes: 30),
        child: MaterialApp(
          title: 'Gemma Health Edge',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          locale: locale,
          localeResolutionCallback: (deviceLocales, supportedLocales) {
            // Always prioritize user's selected language from settings
            if (deviceLocales != null) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode) {
                  return supportedLocale;
                }
              }
            }
            // Fallback to first supported locale
            return supportedLocales.first;
          },

          // ─── Localization ─────────────────────────────────────────
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('fr'),
            Locale('de'),
            Locale('es'),
            Locale('zh'),
            Locale('hi'),
            Locale('ru'),
            Locale('ja'),
            Locale('ko'),
            Locale('mn'),
          ],

          // ─── Dark Theme ───────────────────────────────────────────
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.black,
            colorScheme: ColorScheme.dark(
              primary: accentColor,
              secondary: accentColor,
              surface: Colors.black,
              onSurface: Colors.white.withOpacity(0.92),
            ),
            cardColor: const Color(0xFF1A1A1A),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.black,
            ),
            dividerColor: Colors.white.withOpacity(0.06),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF121218),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: const Color(0xFF263348),
              contentTextStyle: const TextStyle(color: Colors.white),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme)
                .copyWith(
              bodyLarge: GoogleFonts.roboto(
                  textStyle: ThemeData.dark().textTheme.bodyLarge),
              bodyMedium: GoogleFonts.roboto(
                  textStyle: ThemeData.dark().textTheme.bodyMedium),
            ),
          ),

          // ─── Light Theme ──────────────────────────────────────────
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFFAFAFA),
            colorScheme: ColorScheme.light(
              primary: accentColor,
              secondary: accentColor,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            cardColor: const Color(0xFFF5F5F5),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFAFAFA),
              foregroundColor: Colors.black87,
              elevation: 0,
            ),
            dividerColor: Colors.grey.shade200,
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textTheme: GoogleFonts.getTextTheme(
                    'Noto Sans', ThemeData.light().textTheme)
                .copyWith(
              bodyLarge: GoogleFonts.notoSans(
                  textStyle: ThemeData.light().textTheme.bodyLarge),
              bodyMedium: GoogleFonts.notoSans(
                  textStyle: ThemeData.light().textTheme.bodyMedium),
            ),
          ),

          // ─── Routes ───────────────────────────────────────────────
          initialRoute: '/',
          routes: {
            '/': (context) => const _DisclaimerGate(),
            '/settings': (context) => const SettingsScreen(),
            '/calendar': (context) => const CalendarScreen(),
            '/health': (context) => const HealthScreen(),
          },
        ));
  }
}

/// Gate widget that shows the disclaimer on first launch.
class _DisclaimerGate extends ConsumerStatefulWidget {
  const _DisclaimerGate();

  @override
  ConsumerState<_DisclaimerGate> createState() => _DisclaimerGateState();
}

class _DisclaimerGateState extends ConsumerState<_DisclaimerGate> {
  bool _checkedDisclaimer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDisclaimer();
    });
  }

  void _checkDisclaimer() {
    if (_checkedDisclaimer) return;
    _checkedDisclaimer = true;

    final settings = ref.read(settingsProvider).settings;
    if (!settings.disclaimerAccepted) {
      _showDisclaimer();
    }

    // Auto-detect server in background
    ref.read(chatProvider.notifier).checkServerHealth();
  }

  void _showDisclaimer() {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      // Localization not yet ready — retry after frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _showDisclaimer());
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.disclaimerTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.disclaimerBody,
                style: const TextStyle(height: 1.6, fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).acceptDisclaimer();
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.disclaimerAccept),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const ChatScreen();
  }
}
