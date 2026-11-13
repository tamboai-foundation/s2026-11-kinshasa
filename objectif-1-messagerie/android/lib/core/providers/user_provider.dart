import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ngoma/core/platform/account/account_bridge.dart';
import 'package:ngoma/core/shared/media_dto.dart';
import 'package:ngoma/core/superapp/wouanda_service_registry.dart';

enum KYCStatus { unverified, pending, verified }

enum UserServiceStatus { inactive, active, pendingReview, suspended }

enum UserSessionStatus { restoring, guest, authenticated }

class UserSessionStatusNotifier extends Notifier<UserSessionStatus> {
  @override
  UserSessionStatus build() => UserSessionStatus.restoring;

  void markRestoring() => state = UserSessionStatus.restoring;

  void markGuest() => state = UserSessionStatus.guest;

  void markAuthenticated() => state = UserSessionStatus.authenticated;
}

final userSessionStatusProvider =
    NotifierProvider<UserSessionStatusNotifier, UserSessionStatus>(() {
      return UserSessionStatusNotifier();
    });

final isUserSessionReadyProvider = Provider<bool>((ref) {
  return ref.watch(userSessionStatusProvider) != UserSessionStatus.restoring;
});

class UserServiceProfile {
  final String serviceKey;
  final UserServiceStatus status;
  final List<String> roles;
  final Map<String, dynamic> data;
  final DateTime? activatedAt;
  final DateTime? updatedAt;

  const UserServiceProfile({
    required this.serviceKey,
    this.status = UserServiceStatus.inactive,
    this.roles = const [],
    this.data = const {},
    this.activatedAt,
    this.updatedAt,
  });

  bool get isActive => status == UserServiceStatus.active;

  UserServiceProfile copyWith({
    String? serviceKey,
    UserServiceStatus? status,
    List<String>? roles,
    Map<String, dynamic>? data,
    DateTime? activatedAt,
    DateTime? updatedAt,
  }) {
    return UserServiceProfile(
      serviceKey: serviceKey ?? this.serviceKey,
      status: status ?? this.status,
      roles: roles ?? this.roles,
      data: data ?? this.data,
      activatedAt: activatedAt ?? this.activatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'serviceKey': serviceKey,
    'status': status.name,
    'roles': roles,
    'data': data,
    'activatedAt': activatedAt?.millisecondsSinceEpoch,
    'updatedAt': updatedAt?.millisecondsSinceEpoch,
  };

  factory UserServiceProfile.fromJson(Map<String, dynamic> json) {
    return UserServiceProfile(
      serviceKey: json['serviceKey'] as String? ?? '',
      status: _serviceStatusFromJson(json['status']),
      roles: _stringList(json['roles']),
      data: _dynamicMap(json['data']),
      activatedAt: _dateFromMillis(json['activatedAt']),
      updatedAt: _dateFromMillis(json['updatedAt']),
    );
  }

  factory UserServiceProfile.active(
    String serviceKey, {
    List<String> roles = const [],
    Map<String, dynamic> data = const {},
  }) {
    final now = DateTime.now();
    return UserServiceProfile(
      serviceKey: serviceKey,
      status: UserServiceStatus.active,
      roles: roles,
      data: data,
      activatedAt: now,
      updatedAt: now,
    );
  }
}

/// Central identity for the super-app.
///
/// Global identity fields stay here. Domain-specific state belongs in
/// [serviceProfiles] and [servicePreferences], keyed by the service registry.
class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String city;
  final String address;
  final String dob;
  final String gender;
  final String? profilePhotoUrl;
  final String? idFrontUrl;
  final String? idBackUrl;
  final KYCStatus kycStatus;
  final bool isVip;
  final String? sellerId;
  final bool isAnonymous;
  final List<String> roles;

  final List<String> activeServices;
  final String? walletId;
  final double loyaltyPoints;
  final String preferredLanguage;
  final DateTime? lastLoginAt;
  final Map<String, dynamic> servicePreferences;
  final Map<String, UserServiceProfile> serviceProfiles;

  /// Permissions decided by the account authority (`go.drive`, `shop.sell`,
  /// `love.use`…). Never derived from roles here.
  final List<String> permissions;

  /// Access decisions of the session, keyed by action code (contract
  /// account v1.2). Read by `WouandaPermissions`, never recomputed.
  final Map<String, AccountAccessDto> access;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.city,
    required this.address,
    required this.dob,
    required this.gender,
    this.profilePhotoUrl,
    this.idFrontUrl,
    this.idBackUrl,
    this.kycStatus = KYCStatus.unverified,
    this.isVip = false,
    this.sellerId,
    this.isAnonymous = false,
    this.roles = const [],
    this.activeServices = const [
      'go',
      'shop',
      'events',
      'love',
      'stay',
      'scanner',
      'activity',
      'account',
      'wallet',
    ],
    this.walletId,
    this.loyaltyPoints = 0,
    this.preferredLanguage = 'fr',
    this.lastLoginAt,
    this.servicePreferences = const {},
    this.serviceProfiles = const {},
    this.permissions = const [],
    this.access = const {},
  });

  String get fullName => isAnonymous ? 'Invite' : '$firstName $lastName';
  String get initials => isAnonymous
      ? '?'
      : '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase();
  bool get isAuthenticated => !isAnonymous;
  bool get isKYCVerified => kycStatus == KYCStatus.verified;

  /// Whether the account authority granted [permission].
  bool hasPermission(String permission) => permissions.contains(permission);

  UserServiceProfile? serviceProfile(String service) =>
      serviceProfiles[service];

  UserProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? city,
    String? address,
    String? dob,
    String? gender,
    String? profilePhotoUrl,
    String? idFrontUrl,
    String? idBackUrl,
    KYCStatus? kycStatus,
    bool? isVip,
    String? sellerId,
    bool? isAnonymous,
    List<String>? roles,
    List<String>? activeServices,
    String? walletId,
    double? loyaltyPoints,
    String? preferredLanguage,
    DateTime? lastLoginAt,
    Map<String, dynamic>? servicePreferences,
    Map<String, UserServiceProfile>? serviceProfiles,
    List<String>? permissions,
    Map<String, AccountAccessDto>? access,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      address: address ?? this.address,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      idFrontUrl: idFrontUrl ?? this.idFrontUrl,
      idBackUrl: idBackUrl ?? this.idBackUrl,
      kycStatus: kycStatus ?? this.kycStatus,
      isVip: isVip ?? this.isVip,
      sellerId: sellerId ?? this.sellerId,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      roles: roles ?? this.roles,
      activeServices: activeServices ?? this.activeServices,
      walletId: walletId ?? this.walletId,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      servicePreferences: servicePreferences ?? this.servicePreferences,
      serviceProfiles: serviceProfiles ?? this.serviceProfiles,
      permissions: permissions ?? this.permissions,
      access: access ?? this.access,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'city': city,
    'address': address,
    'dob': dob,
    'gender': gender,
    'profilePhotoUrl': profilePhotoUrl,
    'idFrontUrl': idFrontUrl,
    'idBackUrl': idBackUrl,
    'kycStatus': kycStatus.name,
    'isVip': isVip,
    'sellerId': sellerId,
    'isAnonymous': isAnonymous,
    'roles': roles,
    'activeServices': activeServices,
    'walletId': walletId,
    'loyaltyPoints': loyaltyPoints,
    'preferredLanguage': preferredLanguage,
    'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
    'servicePreferences': servicePreferences,
    'serviceProfiles': serviceProfiles.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'permissions': permissions,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final roles = _stringList(json['roles']);
    final sellerId = json['sellerId'] as String?;
    final activeServices = _stringList(json['activeServices']);
    final normalizedActiveServices = activeServices.isEmpty
        ? WouandaServiceRegistry.defaultActiveServiceKeys
        : activeServices;
    final serviceProfiles = _normalizeServiceProfiles(
      rawProfiles: _serviceProfilesFromJson(json['serviceProfiles']),
      activeServices: normalizedActiveServices,
      roles: roles,
      sellerId: sellerId,
    );

    return UserProfile(
      id: json['id'] as String? ?? 'guest',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      dob: json['dob'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      idFrontUrl: json['idFrontUrl'] as String?,
      idBackUrl: json['idBackUrl'] as String?,
      kycStatus: _kycFromJson(json['kycStatus']),
      isVip: json['isVip'] as bool? ?? false,
      sellerId: sellerId,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      roles: roles,
      activeServices: normalizedActiveServices,
      walletId: json['walletId'] as String?,
      loyaltyPoints: (json['loyaltyPoints'] as num?)?.toDouble() ?? 0,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'fr',
      lastLoginAt: _dateFromMillis(json['lastLoginAt']),
      servicePreferences: _dynamicMap(json['servicePreferences']),
      serviceProfiles: serviceProfiles,
      permissions: _stringList(json['permissions']),
    );
  }

  static UserProfile anonymous() => UserProfile(
    id: 'guest',
    firstName: 'Invite',
    lastName: '',
    email: '',
    phone: '',
    city: '',
    address: '',
    dob: '',
    gender: '',
    isAnonymous: true,
    activeServices: const [],
    serviceProfiles: const {},
  );

  /// Fully provisioned local account used only by the non-production MVP mode.
  static UserProfile mvpDemo() {
    const roles = ['seller', 'driver', 'host', 'organizer'];
    final activeServices = WouandaServiceRegistry.defaultActiveServiceKeys;
    return UserProfile(
      id: 'mvp-demo-user',
      firstName: 'MVP',
      lastName: 'Demo',
      email: 'mvp.demo@local.wouanda',
      phone: '+00000000000',
      city: 'Demo',
      address: 'Local development',
      dob: '1990-01-01',
      gender: 'other',
      kycStatus: KYCStatus.verified,
      isAnonymous: false,
      roles: roles,
      activeServices: activeServices,
      serviceProfiles: defaultServiceProfiles(
        activeServices: activeServices,
        roles: roles,
      ),
    );
  }

  static Map<String, UserServiceProfile> defaultServiceProfiles({
    List<String>? activeServices,
    List<String> roles = const [],
    String? sellerId,
  }) {
    final keys = {
      ...(activeServices ?? WouandaServiceRegistry.defaultActiveServiceKeys),
    };
    return {
      for (final key in keys)
        key: UserServiceProfile.active(
          key,
          roles: _rolesForService(key, roles: roles, sellerId: sellerId),
        ),
    };
  }

  static List<String> _rolesForService(
    String serviceKey, {
    required List<String> roles,
    String? sellerId,
  }) {
    final scoped = <String>{};
    if (serviceKey == 'shop' &&
        ((sellerId ?? '').isNotEmpty || roles.contains('seller'))) {
      scoped.add('seller');
    }
    if (serviceKey == 'go' && roles.contains('driver')) scoped.add('driver');
    if (serviceKey == 'stay' && roles.contains('host')) scoped.add('host');
    if (serviceKey == 'events' && roles.contains('organizer')) {
      scoped.add('organizer');
    }
    return scoped.toList(growable: false);
  }
}

class UserNotifier extends Notifier<UserProfile> {
  int _sessionMutationVersion = 0;
  Future<AccountSessionDto>? _restoration;

  @override
  UserProfile build() {
    Future<void>.microtask(() async {
      try {
        await restoreSession();
      } catch (_) {
        /* Splash exposes the retry. */
      }
    });
    return UserProfile.anonymous();
  }

  Future<AccountSessionDto> restoreSession({bool retry = false}) {
    if (retry) _restoration = null;
    return _restoration ??= _restoreSession();
  }

  Future<AccountSessionDto> _restoreSession() async {
    final restoreVersion = _sessionMutationVersion;
    ref.read(userSessionStatusProvider.notifier).markRestoring();

    final restored = await ref.read(accountBridgeProvider).restoreSession();
    if (!ref.mounted || restoreVersion != _sessionMutationVersion) {
      return restored;
    }
    _apply(restored);
    return restored;
  }

  /// The session of the account authority becomes the state: identity,
  /// roles, permissions and access decisions, for a guest too.
  bool _watchingSession = false;
  void _watchSession() {
    if (_watchingSession) return;
    _watchingSession = true;
    final bridge = ref.read(accountBridgeProvider);
    if (bridge is AccountSessionEventsBridge) {
      final subscription = (bridge as AccountSessionEventsBridge).events.listen(
        (key) async {
          if (key == 'session') {
            try {
              final session = await (bridge as AccountSessionEventsBridge)
                  .currentSession();
              if (!ref.mounted) return;
              _sessionMutationVersion++;
              _restoration = Future.value(session);
              _apply(session);
            } catch (_) {
              /* The last native snapshot stays visible. */
            }
          }
        },
        onError: (Object _) {},
      );
      ref.onDispose(subscription.cancel);
    }
  }

  void _apply(AccountSessionDto session) {
    _watchSession();
    final authenticated = session.status == 'authenticated';
    state =
        (authenticated
                ? UserProfile.fromJson({
                    ...session.user!,
                    'id': session.user!['id'].toString(),
                  })
                : UserProfile.anonymous())
            .copyWith(access: session.access);
    final status = ref.read(userSessionStatusProvider.notifier);
    authenticated ? status.markAuthenticated() : status.markGuest();
  }

  /// Runs an account command and applies the session it returns.
  Future<void> _change(
    Future<AccountSessionDto> Function(AccountBridge bridge) command,
  ) async {
    final session = await command(ref.read(accountBridgeProvider));
    if (!ref.mounted) return;
    _sessionMutationVersion++;
    _restoration = Future.value(session);
    _apply(session);
  }

  Future<void> authenticate(
    String identifier,
    String password, {
    bool rememberMe = true,
    String? socialProvider,
  }) => _change(
    (bridge) => socialProvider != null
        ? bridge.socialLogin(socialProvider)
        : bridge.login(identifier, password, rememberMe: rememberMe),
  );

  Future<void> requestSignupCode(String email) =>
      ref.read(accountBridgeProvider).requestOtp(email);

  /// Creates the account once the e-mail code is confirmed by the server.
  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String code,
  }) => _change(
    (bridge) => bridge.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      code: code,
    ),
  );

  Future<void> setGuestMode() async {
    // A restored guest already has the authority's access decisions. Entering
    // the hub does not need a second storage write that could fail offline.
    if (ref.read(userSessionStatusProvider) == UserSessionStatus.guest &&
        state.access['explore']?.allowed == true) {
      return;
    }
    await logout();
    if (state.access['explore']?.allowed != true) {
      throw StateError('L’exploration est indisponible.');
    }
  }

  Future<void> logout() async {
    await _change((bridge) => bridge.logout());
    if (!ref.mounted) return;
    _restoration = null;
  }

  Future<void> updateProfile(UserProfile newProfile) => _change(
    (bridge) => bridge.updateProfile({
      'firstName': newProfile.firstName,
      'lastName': newProfile.lastName,
      'email': newProfile.email,
      'phone': newProfile.phone,
      'city': newProfile.city,
      'address': newProfile.address,
      'dob': newProfile.dob,
      'gender': newProfile.gender,
      'photo': newProfile.profilePhotoUrl == null
          ? null
          : _photo(newProfile.profilePhotoUrl!).toMap(),
    }),
  );

  Future<void> updateServicePreference(
    String service,
    Map<String, dynamic> prefs,
  ) => _change(
    (bridge) => bridge.updateServiceData(service, {'preferences': prefs}),
  );

  /// Reports a service role to the account authority, which decides the
  /// resulting permissions and access (contract account v1.2).
  ///
  /// Les champs d'identité restent dans [UserProfile]. Seuls le statut, le
  /// rôle et les données métier du service sont enregistrés dans son extension.
  Future<void> setServiceRole(
    String service, {
    required String role,
    required bool enabled,
    UserServiceStatus status = UserServiceStatus.active,
    Map<String, dynamic> data = const {},
  }) => _change(
    (bridge) => bridge.setServiceRole(
      service,
      role: role,
      enabled: enabled,
      status: status.name,
      data: data,
    ),
  );

  void setLoyaltyPoints(double points) {
    if (state.loyaltyPoints == points) return;
    state = state.copyWith(
      loyaltyPoints: points,
    ); // Snapshot of Pay, no local ledger.
  }

  /// Sends the identity photos to the account authority. Without a review
  /// backend the mock validates directly; the account profile records it as a
  /// local verification so it is never mistaken for a server review.
  Future<void> completeLocalIdentityVerification({
    required String selfieUrl,
    required String idFrontUrl,
    required String idBackUrl,
  }) => _change(
    (bridge) => bridge.submitKyc(
      selfie: _photo(selfieUrl),
      idFront: _photo(idFrontUrl),
      idBack: _photo(idBackUrl),
      complete: true,
    ),
  );

  static MediaDto _photo(String source) => source.startsWith('http')
      ? MediaDto.image(source)
      : MediaDto(type: MediaType.image, path: source);
}

final userProvider = NotifierProvider<UserNotifier, UserProfile>(() {
  return UserNotifier();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(userProvider).isAuthenticated;
});

Map<String, UserServiceProfile> _normalizeServiceProfiles({
  required Map<String, UserServiceProfile> rawProfiles,
  required List<String> activeServices,
  required List<String> roles,
  String? sellerId,
}) {
  final normalized = Map<String, UserServiceProfile>.from(rawProfiles);
  final validServices = WouandaServiceRegistry.allServiceKeys.toSet();

  normalized.removeWhere((key, _) => !validServices.contains(key));

  for (final key in activeServices.where(validServices.contains)) {
    final current = normalized[key];
    final serviceRoles = {
      ...?current?.roles,
      ...UserProfile._rolesForService(key, roles: roles, sellerId: sellerId),
    }.toList(growable: false);
    normalized[key] = (current ?? UserServiceProfile.active(key)).copyWith(
      serviceKey: key,
      status: UserServiceStatus.active,
      roles: serviceRoles,
      updatedAt: current?.updatedAt ?? DateTime.now(),
    );
  }

  return normalized;
}

Map<String, UserServiceProfile> _serviceProfilesFromJson(Object? value) {
  if (value is! Map) return const {};
  final result = <String, UserServiceProfile>{};
  for (final entry in value.entries) {
    final key = entry.key.toString();
    final data = entry.value;
    if (data is Map) {
      final profile = UserServiceProfile.fromJson(_dynamicMap(data));
      result[key] = profile.serviceKey.isEmpty
          ? profile.copyWith(serviceKey: key)
          : profile;
    }
  }
  return result;
}

Map<String, dynamic> _dynamicMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString())
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);
}

DateTime? _dateFromMillis(Object? value) {
  final millis = value is int ? value : int.tryParse(value?.toString() ?? '');
  if (millis == null || millis <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(millis);
}

KYCStatus _kycFromJson(Object? value) {
  if (value is String) {
    return KYCStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => KYCStatus.unverified,
    );
  }

  final index = value is int ? value : int.tryParse(value?.toString() ?? '');
  if (index == null || index < 0 || index >= KYCStatus.values.length) {
    return KYCStatus.unverified;
  }
  return KYCStatus.values[index];
}

UserServiceStatus _serviceStatusFromJson(Object? value) {
  if (value is String) {
    return UserServiceStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => UserServiceStatus.inactive,
    );
  }

  final index = value is int ? value : int.tryParse(value?.toString() ?? '');
  if (index == null || index < 0 || index >= UserServiceStatus.values.length) {
    return UserServiceStatus.inactive;
  }
  return UserServiceStatus.values[index];
}
