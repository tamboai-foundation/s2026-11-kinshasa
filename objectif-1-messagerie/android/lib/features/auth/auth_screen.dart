import 'package:flutter/material.dart';
import 'package:wouanda_design/wouanda_design.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ngoma/core/architecture/error_handling.dart';
import 'package:ngoma/core/i18n/translations.dart';
import 'package:ngoma/core/onboarding/dynamic_onboarding.dart';
import 'package:ngoma/core/providers/user_provider.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/core/widgets/account_setup_progress.dart';
import 'package:ngoma/core/widgets/language_selector.dart';
import 'package:ngoma/core/widgets/wouanda_brand_mark.dart';
import 'package:ngoma/core/widgets/account_provider_button.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final String? returnTo;
  final bool returnToPrevious;

  const AuthScreen({super.key, this.returnTo, this.returnToPrevious = false});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _pendingProvider;
  bool _isLogin = true;
  // Sign-up has two steps: the server mails a code, then the account is created.
  bool _codeSent = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 760;
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (Navigator.of(context).canPop() ||
                          widget.returnTo != null) ...[
                        IconButton(
                          tooltip: lang.t('auth_back'),
                          icon: const Icon(LucideIcons.arrowLeft),
                          onPressed: _goBack,
                        ),
                        const SizedBox(width: 8),
                      ],
                      const WouandaBrandMark(width: 42),
                    ],
                  ),
                  LanguageSelector(
                    transparent: true,
                    color: AppTheme.getTextPrimary(isDark),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, viewport) => SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: viewport.maxHeight),
                    child: IntrinsicHeight(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 940),
                          child: isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(child: _BrandPane(isDark: isDark)),
                                    const SizedBox(width: 64),
                                    SizedBox(
                                      width: 390,
                                      child: _buildForm(isDark),
                                    ),
                                  ],
                                )
                              : _buildForm(isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (MediaQuery.viewInsetsOf(context).bottom == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _continueAsGuest,
                      child: Text(lang.t('auth_explore')),
                    ),
                  ),
                ),
              ),
            // The Wouanda setup runs right after the sign-in: its progress shows here.
            if (_isSubmitting && _pendingProvider == null)
              const AccountSetupProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    final lang = ref.watch(languageProvider);
    // One group: the phone offers to fill the saved e-mail and password, and to
    // save the new ones when the account is created.
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              lang.t('auth_welcome'),
              style: AppTheme.displayLg(color: AppTheme.getTextPrimary(isDark)),
            ),
            const SizedBox(height: 20),
            if (_isLogin)
              _AuthField(
                controller: _identifierController,
                label: lang.t('auth_identifier'),
                hint: lang.t('auth_identifier_hint'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return lang.t('auth_identifier_required');
                  }
                  return null;
                },
              )
            else ...[
              _AuthField(
                controller: _nameController,
                label: 'Nom complet',
                hint: 'Ex. Amina Wouanda',
                autofillHints: const [AutofillHints.name],
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) => (value ?? '').trim().length < 2
                    ? 'Entrez votre nom complet'
                    : null,
              ),
              const SizedBox(height: 14),
              _AuthField(
                controller: _emailController,
                label: 'Email',
                hint: 'nom@email.com',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                enabled: !_codeSent,
                validator: (value) =>
                    RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch((value ?? '').trim())
                    ? null
                    : 'Entrez un email valide',
              ),
              const SizedBox(height: 14),
              _AuthField(
                controller: _phoneController,
                label: 'Téléphone',
                hint: '+237 6...',
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    (value ?? '').replaceAll(RegExp(r'\D'), '').length < 8
                    ? 'Entrez un numéro valide'
                    : null,
              ),
            ],
            const SizedBox(height: 14),
            _AuthField(
              controller: _passwordController,
              label: lang.t('auth_password'),
              hint: lang.t('auth_password_hint'),
              obscureText: _obscurePassword,
              autofillHints: [
                _isLogin ? AutofillHints.password : AutofillHints.newPassword,
              ],
              // The last field: the keyboard key sends the form.
              textInputAction: !_isLogin && _codeSent
                  ? TextInputAction.next
                  : TextInputAction.done,
              onSubmitted: _isSubmitting ? null : _submit,
              suffix: IconButton(
                tooltip: lang.t(_obscurePassword ? 'auth_show' : 'auth_hide'),
                icon: Icon(
                  _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 18,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return lang.t('auth_password_required');
                }
                return null;
              },
            ),
            if (!_isLogin && _codeSent) ...[
              const SizedBox(height: 14),
              _AuthField(
                controller: _codeController,
                label: 'Code de vérification',
                hint: '6 chiffres reçus par email',
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                textInputAction: TextInputAction.done,
                onSubmitted: _isSubmitting ? null : _submit,
                validator: (value) =>
                    RegExp(r'^\d{6}$').hasMatch((value ?? '').trim())
                    ? null
                    : 'Entrez le code à 6 chiffres',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isSubmitting ? null : _sendCode,
                  child: const Text('Renvoyer le code'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting && _pendingProvider == null
                    ? const WouandaBusyBar(size: 20)
                    : Text(
                        _isLogin
                            ? lang.t('auth_enter')
                            : _codeSent
                            ? lang.t('auth_create')
                            : 'Recevoir le code',
                      ),
              ),
            ),
            // Sign-up is ours: the UI team's screen has no entry for it yet.
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() {
                      _isLogin = !_isLogin;
                      _codeSent = false;
                      _codeController.clear();
                    }),
              child: Text(
                _isLogin
                    ? '${lang.t('auth_no_account')} ${lang.t('auth_create')}'
                    : 'Déjà un compte ? ${lang.t('auth_enter')}',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      lang.t('auth_or'),
                      style: AppTheme.bodyMd(
                        color: AppTheme.getTextSecondary(isDark),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),
            for (final provider in ['google', 'apple']) ...[
              AccountProviderButton(
                provider: provider,
                label: lang.t('auth_$provider'),
                loading: _pendingProvider == provider,
                onPressed: _isSubmitting ? null : () => _socialLogin(provider),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final notifier = ref.read(userProvider.notifier);
      if (_isLogin) {
        await notifier.authenticate(
          _identifierController.text.trim(),
          _passwordController.text,
          rememberMe: true,
        );
      } else if (!_codeSent) {
        final email = _emailController.text.trim();
        await notifier.requestSignupCode(email);
        if (!mounted) return;
        setState(() => _codeSent = true);
        WouandaSnackbar.showWarning(
          context,
          'Un code de vérification vient d’être envoyé à $email.',
        );
        return;
      } else {
        await notifier.register(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          code: _codeController.text.trim(),
        );
      }
      if (!mounted) return;
      await ref.read(onboardingStateProvider.notifier).completeMainOnboarding();
      if (!mounted) return;
      _finishNavigation();
    } catch (error) {
      if (!mounted) return;
      WouandaSnackbar.showWarning(
        context,
        error is PlatformException
            ? (error.message ?? error.code)
            : ref.read(languageProvider).t('auth_unavailable'),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    setState(() => _isSubmitting = true);
    try {
      await ref.read(userProvider.notifier).requestSignupCode(email);
      if (!mounted) return;
      WouandaSnackbar.showWarning(
        context,
        'Un nouveau code vient d’être envoyé à $email.',
      );
    } catch (error) {
      if (!mounted) return;
      WouandaSnackbar.showWarning(
        context,
        error is PlatformException
            ? (error.message ?? error.code)
            : ref.read(languageProvider).t('auth_unavailable'),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _socialLogin(String provider) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _pendingProvider = provider;
    });
    try {
      await ref
          .read(userProvider.notifier)
          .authenticate('', '', socialProvider: provider);
      if (!mounted) return;
      await ref.read(onboardingStateProvider.notifier).completeMainOnboarding();
      if (mounted) _finishNavigation();
    } catch (error) {
      if (!mounted) return;
      if (error is PlatformException &&
          error.code == 'ACCOUNT_AUTH_CANCELLED') {
        return;
      }
      final lang = ref.read(languageProvider);
      WouandaSnackbar.showWarning(
        context,
        error is PlatformException &&
                (error.code == 'ACCOUNT_SOCIAL_NOT_CONFIGURED' ||
                    error.code == 'ACCOUNT_NATIVE_NOT_READY' ||
                    error.code == 'unavailable' ||
                    error.code == 'ACCOUNT_UNAVAILABLE')
            ? lang.t('auth_social_unavailable')
            : lang.t('auth_unavailable'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _pendingProvider = null;
        });
      }
    }
  }

  void _finishNavigation() {
    if (widget.returnToPrevious && context.canPop()) {
      context.pop();
      return;
    }
    context.go(widget.returnTo?.isNotEmpty == true ? widget.returnTo! : '/hub');
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(userProvider.notifier).setGuestMode();
      if (!mounted) return;
      await ref.read(onboardingStateProvider.notifier).completeMainOnboarding();
      if (!mounted) return;
      context.go('/hub');
    } catch (error) {
      if (!mounted) return;
      WouandaSnackbar.showWarning(
        context,
        error is PlatformException
            ? (error.message ?? error.code)
            : ref.read(languageProvider).t('auth_unavailable'),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/hub');
    }
  }
}

class _BrandPane extends StatelessWidget {
  final bool isDark;

  const _BrandPane({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const WouandaBrandMark(width: 96),
        const SizedBox(height: 28),
        Text(
          'Wouanda',
          style: AppTheme.displayXL(
            color: AppTheme.getTextPrimary(isDark),
          ).copyWith(fontSize: 44),
        ),
        const SizedBox(height: 12),
        Text(
          'Tout votre quotidien, au même endroit.',
          style: AppTheme.bodyLg(color: AppTheme.getTextSecondary(isDark)),
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final TextCapitalization textCapitalization;
  final bool enabled;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.validator,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyMd(
            color: AppTheme.getTextPrimary(isDark),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          autocorrect:
              !obscureText && keyboardType != TextInputType.emailAddress,
          enableSuggestions: !obscureText,
          onFieldSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
          style: AppTheme.bodyLg(color: AppTheme.getTextPrimary(isDark)),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            filled: true,
            fillColor: AppTheme.getMuted(isDark),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WouandaSpacing.radiusSmall),
              borderSide: BorderSide(color: AppTheme.getBorder(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WouandaSpacing.radiusSmall),
              borderSide: BorderSide(color: AppTheme.getBorder(isDark)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WouandaSpacing.radiusSmall),
              borderSide: BorderSide(
                color: AppTheme.getTextPrimary(isDark),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
