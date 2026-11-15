import 'dart:async';

import 'package:flutter/widgets.dart';

/// The clock of the bridge authority.
///
/// Deadlines sent by a bridge (offer expiry, free waiting, quote validity)
/// are read against the authority's `serverTime`, never against a phone clock
/// that may be minutes off (contracts GO v1.9, Driver v4.7).
class AuthorityClock {
  /// Aligns on the authority time received with a snapshot; without it the
  /// phone clock is used as is.
  AuthorityClock.sync(DateTime? serverTime, {DateTime? phoneNow})
    : skew = serverTime == null
          ? Duration.zero
          : serverTime.difference(phoneNow ?? DateTime.now());

  /// Phone minus authority offset.
  final Duration skew;

  DateTime now() => DateTime.now().add(skew);

  /// Time left before [deadline], never negative.
  Duration remaining(DateTime deadline) {
    final left = deadline.difference(now());
    return left.isNegative ? Duration.zero : left;
  }
}

/// Rebuilds every second with the authority clock, for a display that goes
/// past its deadline (free waiting, then the fee). [AuthorityCountdown]
/// stops at zero; this keeps ticking while it is mounted.
class AuthorityTicker extends StatefulWidget {
  const AuthorityTicker({
    super.key,
    required this.serverTime,
    required this.builder,
  });

  final DateTime? serverTime;
  final Widget Function(BuildContext context, AuthorityClock clock) builder;

  @override
  State<AuthorityTicker> createState() => _AuthorityTickerState();
}

class _AuthorityTickerState extends State<AuthorityTicker> {
  late AuthorityClock _clock = AuthorityClock.sync(widget.serverTime);
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant AuthorityTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverTime != widget.serverTime) {
      _clock = AuthorityClock.sync(widget.serverTime);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _clock);
}

/// Rebuilds every second while a bridge deadline is shown, with the
/// authority clock. [builder] receives null when there is no deadline.
class AuthorityCountdown extends StatefulWidget {
  const AuthorityCountdown({
    super.key,
    required this.serverTime,
    required this.deadline,
    required this.builder,
  });

  final DateTime? serverTime;
  final DateTime? deadline;
  final Widget Function(BuildContext context, Duration? remaining) builder;

  @override
  State<AuthorityCountdown> createState() => _AuthorityCountdownState();
}

class _AuthorityCountdownState extends State<AuthorityCountdown> {
  late AuthorityClock _clock = AuthorityClock.sync(widget.serverTime);
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant AuthorityCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverTime != widget.serverTime) {
      _clock = AuthorityClock.sync(widget.serverTime);
    }
    if (oldWidget.deadline != widget.deadline) _schedule();
  }

  void _schedule() {
    _tick?.cancel();
    _tick = widget.deadline == null
        ? null
        : Timer.periodic(const Duration(seconds: 1), (_) {
            if (!mounted) return;
            setState(() {});
            // Nothing left to count: stop waking the screen.
            if (_clock.remaining(widget.deadline!) == Duration.zero) {
              _tick?.cancel();
            }
          });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    widget.deadline == null ? null : _clock.remaining(widget.deadline!),
  );
}
