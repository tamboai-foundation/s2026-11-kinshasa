import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ngoma/core/providers/user_provider.dart';
import 'package:ngoma/core/superapp/pro_spaces_provider.dart';
import 'package:ngoma/core/superapp/wouanda_service_registry.dart';
import 'package:ngoma/core/i18n/l10n.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/core/widgets/wouanda_image.dart';
import 'package:wouanda_design/wouanda_design.dart';

/// Shared building blocks of the platform screens (Moi, Paramètres, Tous les
/// services). Every service reuses them so the super-app looks like one
/// product, as in Grab or Revolut.

bool _isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

/// A scrollable page with a title bar; bottom padding clears the navigation.
class WouandaPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final bool showBack;

  const WouandaPage({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackground(isDark),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: showBack,
        title: Text(
          title,
          style: AppTheme.h3(color: AppTheme.getTextPrimary(isDark)),
        ),
        actions: actions,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.paddingOf(context).bottom + 110,
        ),
        children: children,
      ),
    );
  }
}

/// A titled group of tiles on a card, separated by thin dividers.
class SettingsSection extends StatelessWidget {
  final String? title;

  /// Figure at the right end of the title (the total of a day), tabular.
  final String? titleDetail;
  final String? footer;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    this.title,
    this.titleDetail,
    this.footer,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextSecondary(isDark),
                      ),
                    ),
                  ),
                  if (titleDetail != null)
                    Text(
                      titleDetail!,
                      style:
                          AppTheme.font(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextSecondary(isDark),
                          ).copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              // Grouped list (Apple): white card, soft shadow, no border.
              color: AppTheme.getCard(isDark),
              borderRadius: BorderRadius.circular(WouandaSpacing.radiusLarge),
              boxShadow: WouandaElevation.card(Theme.of(context).brightness),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: AppTheme.getBorder(isDark),
                    ),
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                footer!,
                style: AppTheme.bodySm(
                  color: AppTheme.getTextSecondary(isDark),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A navigation row: icon, title, optional subtitle / value / badge.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? badge;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const SettingsTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.value,
    this.badge,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) => WouandaPressScale(
    enabled: onTap != null,
    scale: .985,
    child: _content(context),
  );

  Widget _content(BuildContext context) {
    final isDark = _isDark(context);
    final color = destructive
        ? AppTheme.error
        : (iconColor ?? AppTheme.getTextSecondary(isDark));
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SizedBox(width: 26, child: Icon(icon, size: 20, color: color)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppTheme.font(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: destructive
                                  ? AppTheme.error
                                  : AppTheme.getTextPrimary(isDark),
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          badge!,
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines:
                            1, // one line of help (charter): say more on the page itself
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodySm(
                          color: AppTheme.getTextSecondary(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Text(
                  value!,
                  style: AppTheme.bodySm(
                    color: AppTheme.getTextSecondary(isDark),
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppTheme.getTextTertiary(isDark),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A row with a switch. [onChanged] null = locked (shown with a lock).
class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    return SettingsTile(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      trailing: onChanged == null
          ? Icon(
              LucideIcons.lock,
              size: 16,
              color: AppTheme.getTextTertiary(isDark),
            )
          : Switch.adaptive(
              value: value,
              activeTrackColor: context.palette.accent,
              onChanged: (next) {
                HapticFeedback.selectionClick();
                onChanged!(next);
              },
            ),
    );
  }
}

/// The icon tile of a service, used everywhere a service appears.
///
/// Direction « Apple moderne »: a filled tile in the service hue, lit from
/// the top, with a white glyph — like app icons on iOS.
class ServiceIcon extends StatelessWidget {
  final WouandaServiceDefinition service;
  final double size;

  const ServiceIcon({super.key, required this.service, this.size = 44});

  @override
  Widget build(BuildContext context) =>
      WouandaIconTile(icon: service.icon, color: service.color, size: size);
}

/// The illustrated object of a service (Wouanda illustration family), for
/// home tiles and pro spaces; the flat [ServiceIcon] when a service has no
/// illustration yet.
class ServiceArt extends StatelessWidget {
  final WouandaServiceDefinition service;
  final double size;

  const ServiceArt({super.key, required this.service, this.size = 48});

  static WouandaArt? artOf(WouandaServiceId id) => switch (id) {
    WouandaServiceId.mobility => WouandaArt.mobility,
    WouandaServiceId.market => WouandaArt.shop,
    WouandaServiceId.events => WouandaArt.events,
    WouandaServiceId.stay => WouandaArt.stay,
    WouandaServiceId.love => WouandaArt.love,
    WouandaServiceId.wallet => WouandaArt.pay,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final art = artOf(service.id);
    return art == null
        ? ServiceIcon(service: service, size: size * 0.84)
        : WouandaIllustration(art, size: size, bare: true);
  }
}

/// A filled icon tile in any hue, lit from the top, with a white glyph —
/// the one way Wouanda shows a coloured icon (services, pro spaces…).
class WouandaIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const WouandaIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final top = Color.lerp(color, context.palette.onAccent, 0.18)!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, color],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, size: size * 0.5, color: context.palette.onAccent),
    );
  }
}

/// "Nouveau", "Bêta", "Bientôt" badge; nothing for available services.
class ServiceAvailabilityBadge extends StatelessWidget {
  final WouandaServiceAvailability availability;

  const ServiceAvailabilityBadge({super.key, required this.availability});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, color) = switch (availability) {
      WouandaServiceAvailability.available => ('', Colors.transparent),
      WouandaServiceAvailability.beta => (
        l10n.availabilityBeta,
        context.palette.warning,
      ),
      WouandaServiceAvailability.isNew => (
        l10n.availabilityNew,
        context.palette.positive,
      ),
      WouandaServiceAvailability.comingSoon => (
        l10n.availabilitySoon,
        context.palette.textSecondary,
      ),
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return StatusPill(label: label, color: color);
  }
}

/// Small colored label (status, badge).
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(WouandaSpacing.radiusLarge),
      ),
      child: Text(
        label,
        style: AppTheme.font(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }
}

/// The account avatar (network, local file or initials).
class WouandaAvatar extends StatelessWidget {
  final UserProfile user;
  final double radius;

  const WouandaAvatar({super.key, required this.user, this.radius = 28});

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return WouandaPersonAvatar(
      radius: radius,
      name: user.fullName,
      photoUrl: user.profilePhotoUrl,
      backgroundColor: accent.withValues(alpha: 0.10),
      foregroundColor: accent,
      placeholder: user.isAnonymous
          ? Icon(LucideIcons.user, size: radius, color: accent)
          : Text(user.initials, style: AppTheme.titleMd(color: accent)),
    );
  }
}

/// Color-coded status of a professional space.
class ProSpaceStatusPill extends StatelessWidget {
  final ProSpaceStatus status;

  const ProSpaceStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) => StatusPill(
    label: status.label,
    color: switch (status) {
      ProSpaceStatus.active => context.palette.positive,
      ProSpaceStatus.pending => context.palette.warning,
      ProSpaceStatus.suspended => context.palette.negative,
      ProSpaceStatus.available => context.palette.accent,
    },
  );
}
