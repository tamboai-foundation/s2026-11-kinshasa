import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Locks a feature behind the progress of its Kotlin setup (`chat`, `go`).
///
/// Kotlin installs these features in the background once the home is reached;
/// this screen only shows how far it got, then reveals [child]. Without a
/// native setup (demo account, tests) the child is shown immediately.
class FeatureSetupGate extends StatefulWidget {
  const FeatureSetupGate({
    super.key,
    required this.feature,
    required this.title,
    required this.child,
  });

  /// `chat` or `go`.
  final String feature;
  final String title;
  final Widget child;

  @override
  State<FeatureSetupGate> createState() => _FeatureSetupGateState();
}

class _FeatureSetupGateState extends State<FeatureSetupGate> {
  static const _channel = MethodChannel('com.wouanda/setup');
  Timer? _poll;
  bool _ready = false;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check(start: true);
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check({bool start = false}) async {
    try {
      final status = await _channel.invokeMapMethod<String, Object?>(
        start ? 'start' : 'status',
        {'feature': widget.feature},
      );
      if (!mounted) return;
      final state = status?['status'] as String? ?? 'ready';
      setState(() {
        _ready = state == 'ready';
        _error = state == 'error' ? (status?['error'] as String? ?? '') : null;
        _progress = ((status?['progress'] as num?) ?? 0).toDouble().clamp(0, 1);
      });
      if (_ready || state == 'error') {
        _poll?.cancel();
        _poll = null;
      } else {
        _poll ??= Timer.periodic(
          const Duration(milliseconds: 400),
          (_) => _check(),
        );
      }
    } on MissingPluginException {
      if (mounted) setState(() => _ready = true);
    }
  }

  void _retry() {
    setState(() => _error = null);
    _check(start: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;
    final theme = Theme.of(context);
    final failed = _error != null;
    final percent = (_progress * 100).round();
    return Scaffold(
      appBar: Navigator.of(context).canPop()
          ? AppBar(leading: const BackButton(), title: Text(widget.title))
          : null,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Synchronisation · ${widget.title}',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (failed) ...[
                  Text(
                    'La synchronisation a échoué. Vérifiez votre connexion et réessayez.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _retry,
                    child: const Text('Réessayer'),
                  ),
                ] else ...[
                  LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _progress > 0 ? '$percent %' : 'Préparation…',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos données se synchronisent, vous y êtes presque.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
