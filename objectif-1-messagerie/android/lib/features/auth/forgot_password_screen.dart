import 'package:flutter/material.dart';
import 'package:ngoma/core/widgets/wouanda_image.dart';
import 'package:wouanda_design/wouanda_design.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/core/i18n/translations.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.palette.surface,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: WouandaImage(
                "https://images.unsplash.com/photo-1542281286-9e0a16bb7366?auto=format&fit=crop&w=1200&q=80",
                fallback: const SizedBox.shrink(),
              ),
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? context.palette.media : context.palette.onMedia)
                        .withValues(alpha: 0.2),
                    (isDark ? context.palette.media : context.palette.onMedia)
                        .withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Retour',
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          LucideIcons.arrowLeft,
                          color: AppTheme.getTextPrimary(isDark),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: (AppTheme.getTextPrimary(
                            isDark,
                          )).withValues(alpha: 0.1),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ).animate().fadeIn().slideX(begin: -0.2),

                  const SizedBox(height: 40),

                  // Icon/Visual
                  Center(
                    child:
                        Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: (AppTheme.getTextPrimary(
                                    isDark,
                                  )).withValues(alpha: 0.1),
                                ),
                              ),
                              child: Icon(
                                _isSent
                                    ? LucideIcons.mailCheck
                                    : LucideIcons.lock,
                                size: 72,
                                color: AppTheme.primary,
                              ),
                            )
                            .animate(target: _isSent ? 1 : 0)
                            .scale(duration: 400.ms, curve: Curves.easeOutBack),
                  ),

                  SizedBox(height: 48),

                  Text(
                    _isSent ? lang.t('email_sent') : lang.t('forgot_title'),
                    textAlign: TextAlign.center,
                    style: AppTheme.font(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.getTextPrimary(isDark),
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  SizedBox(height: 16),

                  Text(
                    _isSent ? lang.t('email_sent_desc') : lang.t('forgot_desc'),
                    textAlign: TextAlign.center,
                    style: AppTheme.font(
                      fontSize: 16,
                      color: AppTheme.getTextSecondary(isDark),
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  SizedBox(height: 60),

                  if (!_isSent) ...[
                    TextField(
                      controller: _emailController,
                      style: AppTheme.font(
                        color: AppTheme.getTextPrimary(isDark),
                        fontWeight: FontWeight.w600,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: (AppTheme.getTextPrimary(
                          isDark,
                        )).withValues(alpha: 0.05),
                        labelText: lang.t('auth_email'),
                        labelStyle: AppTheme.font(
                          color: AppTheme.getTextSecondary(isDark),
                        ),
                        prefixIcon: Icon(
                          LucideIcons.mail,
                          color: AppTheme.getTextSecondary(isDark),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: (context.palette.border),
                          ),
                          borderRadius: BorderRadius.circular(
                            WouandaSpacing.radiusLarge,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(
                            WouandaSpacing.radiusLarge,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                  ],

                  const SizedBox(height: 40),

                  SizedBox(
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_isSent) {
                          Navigator.pop(context);
                        } else {
                          if (_emailController.text.isNotEmpty) {
                            setState(() => _isSent = true);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSent
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : (AppTheme.getTextPrimary(isDark)),
                        foregroundColor: _isSent
                            ? AppTheme.primary
                            : (isDark
                                  ? context.palette.textPrimary
                                  : context.palette.onAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            WouandaSpacing.radiusLarge,
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
                        _isSent
                            ? lang.t('back_to_login')
                            : lang.t('send_reset_link'),
                        style: AppTheme.font(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).scale(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
