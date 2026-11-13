import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:wouanda_design/wouanda_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:ngoma/core/theme.dart';

/// Dynamic onboarding with per-service first-time onboarding
/// and skip-if-returning behavior

// Provider tracking which onboardings have been seen
final onboardingStateProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(() {
      return OnboardingNotifier();
    });

class OnboardingState {
  final bool hasSeenMainOnboarding;
  final Set<String>
  seenServiceOnboardings; // 'go', 'shop', 'events', 'love', 'stay'

  const OnboardingState({
    this.hasSeenMainOnboarding = false,
    this.seenServiceOnboardings = const {},
  });

  bool hasSeenService(String service) =>
      seenServiceOnboardings.contains(service);
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  static const String _mainKey = 'wouanda_onboarding_main';
  static const String _servicesKey = 'wouanda_onboarding_services';

  @override
  OnboardingState build() {
    _loadState();
    return const OnboardingState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(_mainKey) ?? false;
    final services = prefs.getStringList(_servicesKey)?.toSet() ?? {};
    state = OnboardingState(
      hasSeenMainOnboarding: hasSeen,
      seenServiceOnboardings: services,
    );
  }

  Future<void> completeMainOnboarding() async {
    state = OnboardingState(
      hasSeenMainOnboarding: true,
      seenServiceOnboardings: state.seenServiceOnboardings,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mainKey, true);
  }

  Future<void> completeServiceOnboarding(String service) async {
    final newSet = {...state.seenServiceOnboardings, service};
    state = OnboardingState(
      hasSeenMainOnboarding: state.hasSeenMainOnboarding,
      seenServiceOnboardings: newSet,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_servicesKey, newSet.toList());
  }

  Future<void> resetAll() async {
    state = const OnboardingState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mainKey);
    await prefs.remove(_servicesKey);
  }
}

/// Service-specific onboarding overlay shown first time a service is opened
class ServiceOnboardingOverlay extends ConsumerWidget {
  final String service;
  final Widget child;

  const ServiceOnboardingOverlay({
    super.key,
    required this.service,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingStateProvider);
    final hasSeen = onboardingState.hasSeenService(service);

    if (hasSeen) return child;

    return Stack(
      children: [
        child,
        _ServiceOnboardingSheet(
          service: service,
          onComplete: () {
            ref
                .read(onboardingStateProvider.notifier)
                .completeServiceOnboarding(service);
          },
        ),
      ],
    );
  }
}

class _ServiceOnboardingSheet extends StatelessWidget {
  final String service;
  final VoidCallback onComplete;

  const _ServiceOnboardingSheet({
    required this.service,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final data = _getServiceData();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: context.palette.media.withValues(alpha: 0.54),
      child: Center(
        child:
            Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(WouandaSpacing.radiusSheet),
                boxShadow: WouandaElevation.card(Theme.of(context).brightness),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Service icon with glow
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: data.color.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(data.icon, size: 40, color: data.color),
                  ).animate().scale(
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Bienvenue sur',
                    style: AppTheme.font(
                      fontSize: 14,
                      color: context.palette.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  SizedBox(height: 4),
                  Text(
                    data.title,
                    style: AppTheme.font(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: data.color,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                  SizedBox(height: 16),
                  Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: AppTheme.font(
                      fontSize: 14,
                      color: context.palette.textSecondary,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 12),
                  // Features list
                  ...data.features.asMap().entries.map((entry) {
                    final i = entry.key;
                    final feature = entry.value;
                    return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: data.color.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  feature.icon,
                                  size: 14,
                                  color: data.color,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature.text,
                                  style: AppTheme.font(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: context.palette.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 500 + i * 100))
                        .slideX(begin: 0.1);
                  }),
                  SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: data.color,
                        foregroundColor: context.palette.onAccent,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            WouandaSpacing.radiusMedium,
                          ),
                          side: BorderSide(
                            color: context.palette.border.withValues(
                              alpha: 0.1,
                            ),
                            width: 1,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'C\'Est parti !',
                        style: AppTheme.font(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
                ],
              ),
            ).animate().scale(
              duration: 400.ms,
              curve: Curves.easeOutBack,
              begin: const Offset(0.9, 0.9),
            ),
      ),
    );
  }

  _ServiceOnboardingData _getServiceData() {
    switch (service) {
      case 'go':
        return _ServiceOnboardingData(
          title: 'Wouanda Go',
          description: 'Votre service de mobilité intelligent.',
          color: AppTheme.wouandaGo,
          icon: LucideIcons.carTaxiFront,
          features: [
            _Feature(LucideIcons.locateFixed, 'Géolocalisation en temps réel'),
            _Feature(LucideIcons.creditCard, 'Paiement via Wouanda Pay'),
            _Feature(LucideIcons.star, 'Notez vos chauffeurs'),
          ],
        );
      case 'shop':
        return _ServiceOnboardingData(
          title: 'Wouanda Shop',
          description: 'Achetez et vendez dans votre communauté.',
          color: AppTheme.wouandaShop,
          icon: LucideIcons.store,
          features: [
            _Feature(LucideIcons.layers, 'Des milliers de produits'),
            _Feature(LucideIcons.truck, 'Livraison rapide'),
            _Feature(LucideIcons.tag, 'Vendez facilement vos produits'),
          ],
        );
      case 'events':
        return _ServiceOnboardingData(
          title: 'Wouanda Events',
          description: 'Découvrez les meilleurs événements.',
          color: AppTheme.wouandaEvents,
          icon: LucideIcons.partyPopper,
          features: [
            _Feature(LucideIcons.mapPin, 'Événements près de vous'),
            _Feature(LucideIcons.ticket, 'Billetterie intégrée'),
            _Feature(LucideIcons.users, 'Organisez vos événements'),
          ],
        );
      case 'love':
        return _ServiceOnboardingData(
          title: 'Wouanda Love',
          description: 'Rencontrez des personnes uniques.',
          color: AppTheme.wouandaLove,
          icon: LucideIcons.heart,
          features: [
            _Feature(LucideIcons.search, 'Profils vérifiés'),
            _Feature(LucideIcons.messageSquare, 'Messagerie instantanée'),
            _Feature(LucideIcons.shield, 'Rencontres sécurisées'),
          ],
        );
      default:
        return _ServiceOnboardingData(
          title: 'Wouanda',
          description: 'Bienvenue dans l\'écosystème.',
          color: AppTheme.wouandaGo,
          icon: LucideIcons.network,
          features: [],
        );
    }
  }
}

class _ServiceOnboardingData {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final List<_Feature> features;

  _ServiceOnboardingData({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.features,
  });
}

class _Feature {
  final IconData icon;
  final String text;
  _Feature(this.icon, this.text);
}
