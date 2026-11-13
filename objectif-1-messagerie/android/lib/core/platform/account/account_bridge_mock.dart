import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:ngoma/core/shared/media_dto.dart';
import 'account_bridge.dart';

/// Mock of the UI <-> TModeler account bridge.
///
/// Any identifier / password signs in. To use the real account, implement
/// [AccountBridge] on top of TModeler and return it from
/// `accountBridgeProvider` (see README.md).
class AccountBridgeMock implements AccountBridge, AccountSessionEventsBridge {
  AccountBridgeMock();

  static const _key = 'ngoma_mock_account';
  static const _actions = [
    'explore',
    'message',
    'save',
    'pay',
    'manageAccount',
    'manageService',
  ];

  final _events = StreamController<String>.broadcast();
  Map<String, dynamic>? _user;

  @override
  Stream<String> get events => _events.stream;

  Map<String, dynamic> _newUser(
    String identifier, {
    String fullName = '',
    String phone = '',
  }) {
    final isMail = identifier.contains('@');
    final name = fullName.trim().isNotEmpty
        ? fullName.trim()
        : (isMail ? identifier.split('@').first : identifier);
    final parts = name.split(' ');
    return {
      'id': 1,
      'firstName': parts.first,
      'lastName': parts.skip(1).join(' '),
      'email': isMail ? identifier : '',
      'phone': isMail ? phone : identifier,
      'kycStatus': 'verified',
      'preferredLanguage': 'fr',
      'activeServices': const ['hub', 'activity'],
    };
  }

  AccountSessionDto _session() => AccountSessionDto(
    status: _user == null ? 'guest' : 'authenticated',
    user: _user,
    destination: _user == null ? '/auth' : '/hub',
    access: {
      for (final action in _actions)
        action: AccountAccessDto(
          action: action,
          allowed: action == 'explore' || _user != null,
          blocker: action == 'explore' || _user != null
              ? 'none'
              : 'authentication',
          resolutionRoute: action == 'explore' || _user != null
              ? null
              : '/auth',
        ),
    },
  );

  Future<AccountSessionDto> _signIn(Map<String, dynamic> user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, user['email'] == '' ? user['phone'] : user['email']);
    _events.add('session');
    return _session();
  }

  @override
  Future<AccountSessionDto> restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final saved = (await SharedPreferences.getInstance()).getString(_key);
    _user = saved == null ? null : _newUser(saved);
    return _session();
  }

  @override
  Future<AccountSessionDto> currentSession() async => _session();

  @override
  Future<AccountSessionDto> login(
    String identifier,
    String password, {
    bool rememberMe = true,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _signIn(_newUser(identifier));
  }

  @override
  Future<AccountSessionDto> logout() async {
    _user = null;
    await (await SharedPreferences.getInstance()).remove(_key);
    _events.add('session');
    return _session();
  }

  @override
  Future<void> requestOtp(String email) async {}

  @override
  Future<AccountSessionDto> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String code,
  }) => _signIn(_newUser(email, fullName: fullName, phone: phone));

  @override
  Future<AccountSessionDto> socialLogin(String provider) =>
      _signIn(_newUser('demo@ngoma.app', fullName: 'Demo NGoma'));

  @override
  Future<AccountSessionDto> updateProfile(Map<String, Object?> fields) async {
    _user = {...?_user, ...fields};
    return _session();
  }

  @override
  Future<List<AccountProSpaceDto>> getProfessionalSpaces() async => const [];

  @override
  Future<AccountSessionDto> activateService(
    String service, {
    List<String> roles = const [],
    Map<String, Object?> data = const {},
  }) async => _session();

  @override
  Future<AccountSessionDto> setServiceRole(
    String service, {
    required String role,
    required bool enabled,
    required String status,
    Map<String, Object?> data = const {},
  }) async => _session();

  @override
  Future<AccountSessionDto> deactivateService(String service) async =>
      _session();

  @override
  Future<AccountSessionDto> updateServiceData(
    String service,
    Map<String, Object?> data,
  ) async => _session();

  @override
  Future<AccountSessionDto> submitKyc({
    required MediaDto selfie,
    required MediaDto idFront,
    required MediaDto idBack,
    required bool complete,
  }) async => _session();
}
