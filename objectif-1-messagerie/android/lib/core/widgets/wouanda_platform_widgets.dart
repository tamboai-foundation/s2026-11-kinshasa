import 'package:flutter/material.dart';
import 'package:wouanda_design/wouanda_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ngoma/core/providers/user_provider.dart';
import 'package:ngoma/core/superapp/service_text.dart';
import 'package:ngoma/core/superapp/wouanda_service_registry.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/core/widgets/wouanda_image.dart';
import 'package:ngoma/core/widgets/wouanda_tappable.dart';

/// Pont visuel commun entre un service et l'unique compte Wouanda.
///
/// Les services peuvent afficher leur rôle et leur statut, mais ne recréent
/// jamais un profil, une identité ou des paramètres de sécurité séparés.
class WouandaAccountBridgeCard extends ConsumerWidget {
  final WouandaServiceDefinition service;
  final String? role;
  final String? roleLabel;
  final String? subtitle;
  final EdgeInsetsGeometry padding;

  const WouandaAccountBridgeCard({
    super.key,
    required this.service,
    this.role,
    this.roleLabel,
    this.subtitle,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final profile = user.serviceProfile(service.key);
    // Roles as the account authority reports them (display only).
    final hasRole = role != null && profile?.roles.contains(role) == true;
    final status = switch (profile?.status) {
      UserServiceStatus.pendingReview => 'Validation en attente',
      UserServiceStatus.suspended => 'Accès suspendu',
      _ when hasRole => roleLabel ?? 'Rôle actif',
      _ when user.isAnonymous => 'Connexion requise',
      _ when user.isKYCVerified => 'Identité vérifiée',
      _ => 'Identité à vérifier',
    };

    // Neutral like every card (charter §12, §15): the service tint stays on
    // service icons; a state gets colour only when it is good news.
    final palette = context.palette;
    final good = hasRole || (user.isKYCVerified && profile?.status == null);
    final warning =
        profile?.status == UserServiceStatus.suspended ||
        profile?.status == UserServiceStatus.pendingReview;
    return Semantics(
      button: true,
      label: 'Ouvrir votre compte Wouanda. $status',
      excludeSemantics: true,
      child: WouandaTappable(
        onTap: () => context.push(user.isAnonymous ? '/auth' : '/profile'),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(WouandaSpacing.radiusLarge),
            boxShadow: WouandaElevation.card(Theme.of(context).brightness),
          ),
          child: Row(
            children: [
              WouandaPersonAvatar(
                name: user.isAnonymous ? 'W' : user.fullName,
                photoUrl: user.isAnonymous ? null : user.profilePhotoUrl,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.isAnonymous ? 'Compte Wouanda' : user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.titleMd(color: palette.textPrimary),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodySm(color: palette.textSecondary),
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          warning
                              ? LucideIcons.clock3
                              : user.isKYCVerified
                              ? LucideIcons.badgeCheck
                              : LucideIcons.shieldCheck,
                          size: 14,
                          color: good
                              ? palette.positive
                              : palette.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.caption(
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: palette.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WouandaServiceBadge extends StatelessWidget {
  final WouandaServiceDefinition service;
  final bool dense;

  const WouandaServiceBadge({
    super.key,
    required this.service,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 9 : 12,
        vertical: dense ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: context.palette.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: context.palette.accent.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            service.icon,
            color: context.palette.accent,
            size: dense ? 15 : 17,
          ),
          SizedBox(width: dense ? 6 : 8),
          Text(
            service.productName,
            style: AppTheme.btnSm(color: context.palette.accent),
          ),
        ],
      ),
    );
  }
}

/// A readable dashboard selector shared by service management surfaces.
///
/// It deliberately scrolls instead of compressing labels below an accessible
/// size. Counts remain secondary and every target stays at least 48 px high.
class WouandaDashboardTab {
  final String label;
  final int? count;
  final IconData? icon;

  const WouandaDashboardTab(this.label, {this.count, this.icon});
}

class WouandaDashboardTabs extends StatelessWidget {
  final List<WouandaDashboardTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color accentColor;

  const WouandaDashboardTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      container: true,
      label: 'Sections du tableau de bord',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final selected = index == selectedIndex;

            return Padding(
              padding: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 8),
              child: Semantics(
                button: true,
                selected: selected,
                label: tab.count == null
                    ? tab.label
                    : '${tab.label}, ${tab.count} élément${tab.count == 1 ? '' : 's'}',
                child: Material(
                  color: selected
                      ? accentColor.withValues(alpha: isDark ? 0.20 : 0.10)
                      : AppTheme.getCard(isDark),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: InkWell(
                    key: ValueKey('dashboard-tab-${tab.label}'),
                    onTap: () => onSelected(index),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        border: Border.all(
                          color: selected
                              ? accentColor.withValues(alpha: 0.55)
                              : AppTheme.getBorder(isDark),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tab.icon != null) ...[
                            Icon(
                              tab.icon,
                              size: 17,
                              color: selected
                                  ? accentColor
                                  : AppTheme.getTextSecondary(isDark),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            tab.label,
                            style: AppTheme.font(
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: AppTheme.getTextPrimary(isDark),
                            ),
                          ),
                          if (tab.count != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              constraints: const BoxConstraints(
                                minWidth: 22,
                                minHeight: 22,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? accentColor.withValues(alpha: 0.16)
                                    : AppTheme.getSurface(isDark),
                                borderRadius: BorderRadius.circular(
                                  WouandaSpacing.radiusPill,
                                ),
                              ),
                              child: Text(
                                '${tab.count}',
                                style: AppTheme.font(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? AppTheme.getTextPrimary(isDark)
                                      : AppTheme.getTextSecondary(isDark),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// TabBar counterpart of [WouandaDashboardTabs] for screens backed by a
/// TabController. It keeps the same readable type, rounded selected state and
/// horizontal overflow behavior across Stay, Events and Shop.
class WouandaServiceTabBar extends StatelessWidget {
  final List<String> labels;
  final Color accentColor;
  final TabController? controller;

  const WouandaServiceTabBar({
    super.key,
    required this.labels,
    required this.accentColor,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: accentColor.withValues(alpha: 0.50)),
      ),
      labelColor: AppTheme.getTextPrimary(isDark),
      unselectedLabelColor: AppTheme.getTextSecondary(isDark),
      labelStyle: AppTheme.font(fontSize: 13, fontWeight: FontWeight.w800),
      unselectedLabelStyle: AppTheme.font(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      tabs: labels
          .map(
            (label) => Tab(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class WouandaServiceHeader extends StatelessWidget {
  final WouandaServiceDefinition service;
  final String? title;
  final String? subtitle;
  final Widget? trailing;

  const WouandaServiceHeader({
    super.key,
    required this.service,
    this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.palette.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: context.palette.accent.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(service.icon, color: context.palette.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? service.productName,
                  style: AppTheme.h2(color: AppTheme.getTextPrimary(isDark)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle ?? service.descriptionOf(context),
                  style: AppTheme.bodySm(
                    color: AppTheme.getTextSecondary(isDark),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class WouandaServiceGrid extends StatelessWidget {
  final List<WouandaServiceDefinition> services;

  const WouandaServiceGrid({super.key, this.services = const []});

  @override
  Widget build(BuildContext context) {
    final entries = services.isEmpty
        ? WouandaServiceRegistry.hubServices
        : services;

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final service = entries[index];
        return WouandaServiceTile(
          service: service,
          onTap: () => context.go(service.route),
        );
      },
    );
  }
}

class WouandaServiceTile extends StatelessWidget {
  final WouandaServiceDefinition service;
  final VoidCallback? onTap;

  const WouandaServiceTile({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: AppTheme.getCard(isDark),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.getBorder(isDark).withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: service.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(service.icon, color: service.color, size: 20),
              ),
              const Spacer(),
              Text(
                service.productName,
                style: AppTheme.titleMd(color: AppTheme.getTextPrimary(isDark)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                service.descriptionOf(context),
                style: AppTheme.caption(
                  color: AppTheme.getTextSecondary(isDark),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WouandaEmptyState extends StatelessWidget {
  final IconData icon;

  /// Dedicated illustration; the generic one is built from [icon].
  final WouandaArt? art;
  final double illustrationSize;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const WouandaEmptyState({
    super.key,
    this.icon = LucideIcons.info,
    this.art,
    this.illustrationSize = 104,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: art == null
                        ? WouandaIllustration.icon(icon, size: illustrationSize)
                        : WouandaIllustration(art!, size: illustrationSize),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTheme.titleLg(
                      color: AppTheme.getTextPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyMd(
                      color: AppTheme.getTextSecondary(isDark),
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
