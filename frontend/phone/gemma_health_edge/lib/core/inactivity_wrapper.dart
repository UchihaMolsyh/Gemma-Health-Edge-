import 'dart:async';
import 'package:flutter/material.dart';
import 'i18n/app_localizations.dart';

/// Wraps the application to enforce a 30-minute inactivity lock (BUG-011).
/// Matches the PC frontend's GHE.Vault.lock() behavior.
class InactivityWrapper extends StatefulWidget {
  final Widget child;
  final Duration timeout;

  const InactivityWrapper({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 30),
  });

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper> {
  Timer? _inactivityTimer;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    if (_isLocked) return;
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(widget.timeout, _lockApp);
  }

  void _lockApp() {
    if (mounted && !_isLocked) {
      setState(() {
        _isLocked = true;
      });
    }
  }

  void _unlockApp() {
    setState(() {
      _isLocked = false;
    });
    _resetTimer();
  }

  void _handleInteraction([_]) {
    _resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleInteraction,
      onPointerMove: _handleInteraction,
      onPointerUp: _handleInteraction,
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          widget.child,
          if (_isLocked)
            Positioned.fill(
              child: _LockScreenOverlay(onUnlock: _unlockApp),
            ),
        ],
      ),
    );
  }
}

class _LockScreenOverlay extends StatefulWidget {
  final VoidCallback onUnlock;

  const _LockScreenOverlay({required this.onUnlock});

  @override
  State<_LockScreenOverlay> createState() => _LockScreenOverlayState();
}

class _LockScreenOverlayState extends State<_LockScreenOverlay> {
  final TextEditingController _pinController = TextEditingController();
  bool _error = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyPin() {
    // For BUG-011 demonstration parity, any 4+ digit PIN unlocks for now,
    // until full encrypted Vault (BUG-009) is implemented.
    if (_pinController.text.length >= 4) {
      widget.onUnlock();
    } else {
      setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // We use a Localizations override in case it's not available in the overlay context yet
    final titleText = l10n?.appTitle ?? 'Gemma Health Edge';
    final lockedText = 'Session Locked';
    final unlockText = 'Unlock';

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                titleText,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                lockedText,
                style: TextStyle(
                    fontSize: 16, color: theme.textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                textAlign: TextAlign.center,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'Enter PIN',
                  errorText: _error ? 'PIN must be at least 4 digits' : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (_) => _verifyPin(),
                onChanged: (_) {
                  if (_error) setState(() => _error = false);
                },
                onTap: () {
                  if (_error) setState(() => _error = false);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _verifyPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(unlockText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
