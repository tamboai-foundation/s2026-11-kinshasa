import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Progress of the Wouanda setup that Kotlin runs while a sign-in is in flight.
///
/// The home needs the Wouanda data (services, user directory), so `login`,
/// `register` and `restoreSession` only answer once it is installed. While the
/// call is pending, this polls `setupStatus` and, once the setup runs, covers
/// the screen with its progress. Nothing is drawn outside a setup, and without
/// a native setup (demo account, tests) it stays invisible.
class AccountSetupProgress extends StatefulWidget {
  const AccountSetupProgress({super.key, this.fullScreen = true});

  /// Opaque full-screen cover (login) or just the inline indicator (splash).
  final bool fullScreen;

  @override
  State<AccountSetupProgress> createState() => _AccountSetupProgressState();
}

class _AccountSetupProgressState extends State<AccountSetupProgress> {
  static const _channel = MethodChannel('com.wouanda/account');
  Timer? _poll;
  bool _running = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(milliseconds: 400), (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final status = await _channel.invokeMapMethod<String, Object?>(
        'setupStatus',
      );
      if (!mounted) return;
      setState(() {
        _running = status?['status'] == 'running';
        _progress = ((status?['progress'] as num?) ?? 0).toDouble().clamp(0, 1);
      });
    } on MissingPluginException {
      _poll?.cancel();
      _poll = null;
    } on PlatformException {
      // The next tick asks again.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_running) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final percent = (_progress * 100).round();
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Installation de votre espace Wouanda',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(value: _progress > 0 ? _progress : null),
          const SizedBox(height: 12),
          Text(
            _progress > 0 ? '$percent %' : 'Préparation…',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Chargement des services et de l’annuaire. Quelques instants…',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
    if (!widget.fullScreen) return content;
    return Positioned.fill(
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: Center(child: content),
      ),
    );
  }
}
