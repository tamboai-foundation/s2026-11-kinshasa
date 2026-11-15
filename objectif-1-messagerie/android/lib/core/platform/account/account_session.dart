import 'package:flutter/services.dart';
import 'package:ngoma/core/shared/media_dto.dart';
import 'package:ngoma/core/superapp/mvp_mode.dart';

/// Decision of the account authority for one action (contract account
/// v1.2 `Access`). Flutter words it; it never recomputes it.
class AccountAccessDto {
  final String action;
  final bool allowed;

  /// `none`, `authentication`, `inactiveService`, `phoneVerification`,
  /// `identityVerification`, `serviceApproval` or `role`.
  final String blocker;
  final String? resolutionRoute;

  const AccountAccessDto({
    required this.action,
    required this.allowed,
    required this.blocker,
    this.resolutionRoute,
  });

  static AccountAccessDto? tryParse(Object? raw) {
    if (raw is! Map ||
        raw['action'] is! String ||
        raw['allowed'] is! bool ||
        raw['blocker'] is! String ||
        (raw['resolutionRoute'] != null && raw['resolutionRoute'] is! String)) {
      return null;
    }
    return AccountAccessDto(
      action: raw['action'] as String,
      allowed: raw['allowed'] as bool,
      blocker: raw['blocker'] as String,
      resolutionRoute: raw['resolutionRoute'] as String?,
    );
  }
}

/// Snapshot decoded from the account authority. No routing decision is made here.
class AccountSessionDto {
  final String status;
  final Map<String, dynamic>? user;
  final String destination;

  /// One decision per action, keyed by its contract code.
  final Map<String, AccountAccessDto> access;

  const AccountSessionDto({
    required this.status,
    required this.user,
    required this.destination,
    this.access = const {},
  });

  factory AccountSessionDto.fromMap(Map<String, dynamic> map) {
    final status = map['status'];
    final destination = map['destination'];
    final rawUser = map['user'];
    final rawAccess = map['access'];
    final access = rawAccess is List
        ? rawAccess.map(AccountAccessDto.tryParse).toList()
        : null;
    if (access == null || access.contains(null)) {
      throw PlatformException(
        code: 'ACCOUNT_INVALID_RESPONSE',
        message: 'Réponse du compte invalide.',
      );
    }
    if ((status != 'guest' && status != 'authenticated') ||
        (destination != '/auth' && destination != '/hub') ||
        (status == 'guest' && rawUser != null) ||
        (status == 'authenticated' &&
            (rawUser is! Map ||
                rawUser['id'] is! int ||
                (rawUser['id'] as int) <= 0))) {
      throw PlatformException(
        code: 'ACCOUNT_INVALID_RESPONSE',
        message: 'Réponse du compte invalide.',
      );
    }
    return AccountSessionDto(
      status: status as String,
      user: rawUser == null ? null : Map<String, dynamic>.from(rawUser as Map),
      destination: destination as String,
      access: {for (final entry in access) entry!.action: entry},
    );
  }
}

/// Both mock Kotlin and future TModeler use the same wire contract.
class AccountSessionChannel {
  const AccountSessionChannel();
  static const _channel = MethodChannel('com.wouanda/account');

  Future<AccountSessionDto> restoreSession() =>
      _session('restoreSession', {'demoMode': WouandaMvpMode.enabled});
  Future<AccountSessionDto> currentSession() =>
      _session('getSessionSnapshot', const {});

  Future<AccountSessionDto> login(
    String identifier,
    String password, {
    bool rememberMe = true,
  }) => _session('login', {
    'identifier': identifier,
    'password': password,
    'rememberMe': rememberMe,
  });

  Future<AccountSessionDto> logout() => _session('logout', const {});

  /// Sends the verification code to [email]. Kotlin owns the OTP rules.
  Future<void> requestOtp(String email) async {
    await _channel.invokeMethod<Object?>('requestOtp', {'email': email});
  }

  Future<AccountSessionDto> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String code,
  }) => _session('register', {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'password': password,
    'code': code,
  });

  Future<AccountSessionDto> socialLogin(String provider) =>
      _session('socialLogin', {'provider': provider});

  Future<AccountSessionDto> updateProfile(Map<String, Object?> fields) =>
      _session('updateProfile', {'fields': fields});

  // ─── Account changes (contract v1.2): each returns the whole session ───

  Future<AccountSessionDto> activateService(
    String service, {
    List<String> roles = const [],
    Map<String, Object?> data = const {},
  }) => _session('activateService', {
    'service': service,
    'roles': roles,
    'data': data,
  });

  Future<AccountSessionDto> setServiceRole(
    String service, {
    required String role,
    required bool enabled,
    required String status,
    Map<String, Object?> data = const {},
  }) => _session('setServiceRole', {
    'service': service,
    'role': role,
    'enabled': enabled,
    'status': status,
    'data': data,
  });

  Future<AccountSessionDto> deactivateService(String service) =>
      _session('deactivateService', {'service': service});

  Future<AccountSessionDto> updateServiceData(
    String service,
    Map<String, Object?> data,
  ) => _session('updateServiceData', {'service': service, 'data': data});

  /// Photos as contract media; [complete] when the authority validates
  /// directly (mock), otherwise the review stays pending.
  Future<AccountSessionDto> submitKyc({
    required MediaDto selfie,
    required MediaDto idFront,
    required MediaDto idBack,
    required bool complete,
  }) => _session('submitKyc', {
    'selfie': selfie.toMap(),
    'idFront': idFront.toMap(),
    'idBack': idBack.toMap(),
    'complete': complete,
  });

  Future<AccountSessionDto> _session(
    String method,
    Map<String, Object?> arguments,
  ) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      method,
      arguments,
    );
    if (result == null) {
      throw PlatformException(code: 'ACCOUNT_INVALID_RESPONSE');
    }
    return AccountSessionDto.fromMap(result);
  }
}
