import 'package:flutter/foundation.dart';

/// Shared visibility for notices, regardless of the service entry point.
final activeMessagingConversation = ValueNotifier<int?>(null);
