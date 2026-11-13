import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ngoma/core/platform/account/account_bridge.dart';
import 'package:ngoma/core/providers/user_provider.dart';

import 'wouanda_service_registry.dart';

enum ProSpaceStatus {
  available('Devenir'),
  pending('En validation'),
  active('Actif'),
  suspended('Suspendu');

  final String label;
  const ProSpaceStatus(this.label);
}

class ProSpaceEntry {
  final WouandaServiceDefinition service;
  final WouandaProSpace space;
  final ProSpaceStatus status;

  const ProSpaceEntry({
    required this.service,
    required this.space,
    required this.status,
  });

  String get route => status == ProSpaceStatus.available
      ? space.becomeRoute
      : space.manageRoute;
}

class ProSpacesNotifier extends StateNotifier<List<ProSpaceEntry>> {
  ProSpacesNotifier(this._bridge, {this.onStatus}) : super(const []) {
    Future<void>.microtask(load);
  }

  final AccountBridge _bridge;
  final void Function(AsyncValue<void>)? onStatus;

  Future<void> load() async {
    onStatus?.call(const AsyncLoading());
    try {
      final resolved = await _bridge.getProfessionalSpaces();
      if (!mounted) return;
      state = [
        for (final item in resolved)
          if (WouandaServiceRegistry.tryByKey(item.service) case final service?)
            for (final space in service.proSpaces)
              if (space.role == item.role)
                ProSpaceEntry(
                  service: service,
                  space: space,
                  status: ProSpaceStatus.values.byName(item.status.name),
                ),
      ];
      onStatus?.call(const AsyncData(null));
    } catch (error, stack) {
      if (mounted) onStatus?.call(AsyncError(error, stack));
    }
  }
}

final proSpacesStatusProvider = StateProvider<AsyncValue<void>>(
  (ref) => const AsyncLoading(),
);
final proSpacesProvider =
    StateNotifierProvider<ProSpacesNotifier, List<ProSpaceEntry>>((ref) {
      ref.watch(userProvider);
      return ProSpacesNotifier(
        ref.watch(accountBridgeProvider),
        onStatus: (status) =>
            ref.read(proSpacesStatusProvider.notifier).state = status,
      );
    });
