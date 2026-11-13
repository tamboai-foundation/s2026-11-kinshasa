import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:ngoma/core/shared/media_dto.dart';
import 'account_bridge_mock.dart';
import 'account_session.dart';
import '../bridge_batch.dart';
export 'account_session.dart' show AccountAccessDto, AccountSessionDto;

enum AccountProSpaceStatus { available, pending, active, suspended }

class AccountProSpaceDto {
  final String service;
  final String role;
  final AccountProSpaceStatus status;

  const AccountProSpaceDto({
    required this.service,
    required this.role,
    required this.status,
  });

  factory AccountProSpaceDto.fromMap(Map<String, dynamic> map) =>
      AccountProSpaceDto(
        service: map['service'] as String? ?? '',
        role: map['role'] as String? ?? '',
        status: AccountProSpaceStatus.values.firstWhere(
          (value) => value.name == map['status'],
          orElse: () => AccountProSpaceStatus.available,
        ),
      );
}

/// Account contract extension. Kotlin resolves professional-space eligibility.
abstract class AccountBridge {
  Future<AccountSessionDto> restoreSession();
  Future<AccountSessionDto> login(
    String identifier,
    String password, {
    bool rememberMe = true,
  });

  /// Returns the guest session (contract v1.2).
  Future<AccountSessionDto> logout();
  /// Sends the sign-up verification code to the e-mail address.
  Future<void> requestOtp(String email);
  Future<AccountSessionDto> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String code,
  });
  Future<AccountSessionDto> socialLogin(String provider);
  Future<AccountSessionDto> updateProfile(Map<String, Object?> fields);
  Future<List<AccountProSpaceDto>> getProfessionalSpaces();

  // Account changes (contract v1.2): the authority recomputes roles,
  // permissions and access, and returns the whole session.
  Future<AccountSessionDto> activateService(
    String service, {
    List<String> roles = const [],
    Map<String, Object?> data = const {},
  });
  Future<AccountSessionDto> setServiceRole(
    String service, {
    required String role,
    required bool enabled,
    required String status,
    Map<String, Object?> data = const {},
  });
  Future<AccountSessionDto> deactivateService(String service);
  Future<AccountSessionDto> updateServiceData(
    String service,
    Map<String, Object?> data,
  );
  Future<AccountSessionDto> submitKyc({
    required MediaDto selfie,
    required MediaDto idFront,
    required MediaDto idBack,
    required bool complete,
  });
}

/// Native/server stand-in. It is the only place that interprets local account
/// fields while the real account MethodChannel is not available.
abstract interface class AccountSessionEventsBridge {
  Stream<String> get events;
  Future<AccountSessionDto> currentSession();
}

class AccountBridgeNative implements AccountBridge, AccountSessionEventsBridge {
  final AccountSessionChannel _channel = const AccountSessionChannel();

  const AccountBridgeNative();
  static final _events = const EventChannel(
    'com.wouanda/account/events',
  ).receiveBroadcastStream().cast<String>();
  @override
  Stream<String> get events => _events;
  @override
  Future<AccountSessionDto> currentSession() => _channel.currentSession();

  @override
  Future<AccountSessionDto> restoreSession() => _channel.restoreSession();
  @override
  Future<AccountSessionDto> login(
    String identifier,
    String password, {
    bool rememberMe = true,
  }) => _channel.login(identifier, password, rememberMe: rememberMe);
  @override
  Future<AccountSessionDto> logout() => _channel.logout();
  @override
  Future<void> requestOtp(String email) => _channel.requestOtp(email);
  @override
  Future<AccountSessionDto> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String code,
  }) => _channel.register(
    fullName: fullName,
    email: email,
    phone: phone,
    password: password,
    code: code,
  );
  @override
  Future<AccountSessionDto> socialLogin(String provider) =>
      _channel.socialLogin(provider);

  @override
  Future<AccountSessionDto> updateProfile(Map<String, Object?> fields) =>
      _channel.updateProfile(fields);

  @override
  Future<AccountSessionDto> activateService(
    String service, {
    List<String> roles = const [],
    Map<String, Object?> data = const {},
  }) => _channel.activateService(service, roles: roles, data: data);

  @override
  Future<AccountSessionDto> setServiceRole(
    String service, {
    required String role,
    required bool enabled,
    required String status,
    Map<String, Object?> data = const {},
  }) => _channel.setServiceRole(
    service,
    role: role,
    enabled: enabled,
    status: status,
    data: data,
  );

  @override
  Future<AccountSessionDto> deactivateService(String service) =>
      _channel.deactivateService(service);

  @override
  Future<AccountSessionDto> updateServiceData(
    String service,
    Map<String, Object?> data,
  ) => _channel.updateServiceData(service, data);

  @override
  Future<AccountSessionDto> submitKyc({
    required MediaDto selfie,
    required MediaDto idFront,
    required MediaDto idBack,
    required bool complete,
  }) => _channel.submitKyc(
    selfie: selfie,
    idFront: idFront,
    idBack: idBack,
    complete: complete,
  );

  @override
  Future<List<AccountProSpaceDto>> getProfessionalSpaces() async {
    final items = await const MethodChannel(
      'com.wouanda/account',
    ).invokeListMethod<Object?>('getProfessionalSpaces');
    if (items == null) {
      throw PlatformException(code: 'ACCOUNT_INVALID_RESPONSE');
    }
    return [
      for (final item in items)
        AccountProSpaceDto.fromMap(Map<String, dynamic>.from(item as Map)),
    ];
  }
}

final accountBridgeProvider = Provider<AccountBridge>(
  (ref) => AccountBridgeMock(),
);

/// Account address wire port. IDs and pagination are allocated by Kotlin.
class AccountAddressesBridge {
  const AccountAddressesBridge();
  static const _channel = MethodChannel('com.wouanda/account');
  Future<BridgeBatch<Map<String, dynamic>>> load({bool more = false}) async {
    final raw = await _channel.invokeMapMethod<String, dynamic>(
      more ? 'loadMoreAddresses' : 'loadAddresses',
    );
    if (raw == null) throw PlatformException(code: 'ACCOUNT_INVALID_RESPONSE');
    return BridgeBatch.fromMap(
      raw,
      (item) => {
        ...item,
        'coordinates': item['lat'] == null ? null : [item['lng'], item['lat']],
        'lastUsed': item['lastUsedAt'] == null
            ? null
            : DateTime.parse(
                item['lastUsedAt'] as String,
              ).millisecondsSinceEpoch,
      },
    );
  }

  Future<void> save(Map<String, Object?> fields, {String? id}) async {
    await _channel.invokeMethod<Object?>('saveAddress', {
      'id': id == null ? null : int.parse(id),
      'fields': {
        ...(Map<String, Object?>.from(fields)
          ..remove('coordinates')
          ..remove('lastUsed')
          ..remove('usageCount')
          ..remove('color')),
        'lat': (fields['coordinates'] as List?)?.elementAtOrNull(1),
        'lng': (fields['coordinates'] as List?)?.elementAtOrNull(0),
      },
    });
  }

  Future<void> remove(String id) async =>
      _channel.invokeMethod<void>('removeAddress', {'id': int.parse(id)});
  Future<void> markUsed(String id) async =>
      _channel.invokeMethod<void>('markAddressUsed', {'id': int.parse(id)});
}

final accountAddressesBridgeProvider = Provider(
  (ref) => const AccountAddressesBridge(),
);
