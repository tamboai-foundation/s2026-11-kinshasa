import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wouanda_design/wouanda_design.dart';
import 'package:ngoma/core/i18n/translations.dart';
import 'package:ngoma/core/providers/user_provider.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/core/widgets/account_setup_progress.dart';
import 'package:ngoma/core/widgets/wouanda_brand_mark.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isRestoring = true;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeApp();
    });
  }

  Future<void> _initializeApp({bool retry = false}) async {
    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });
    // Presentation overlaps restoration; only the bridge decides readiness.
    final presentation = Future<void>.delayed(
      retry ? Duration.zero : const Duration(milliseconds: 900),
    );
    try {
      final session = await ref
          .read(userProvider.notifier)
          .restoreSession(retry: retry);
      await presentation;
      if (!mounted) return;
      context.go(session.destination);
    } catch (error) {
      if (!mounted) return;
      final lang = ref.read(languageProvider);
      setState(() {
        _isRestoring = false;
        _errorMessage = error is PlatformException
            ? (error.message ?? error.code)
            : lang.t('auth_unavailable');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppTheme.lightBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.lightBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Matches the native full-window centre and artwork width.
            const Center(child: WouandaBrandMark(width: 104)),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                minimum: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang.t('wallet_slogan'),
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMd(
                        color: AppTheme.getTextSecondary(false),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 8,
                      child: _isRestoring
                          ? const WouandaBusyBar(color: AppTheme.primary)
                          : null,
                    ),
                    // Hybride : la restauration affiche la progression du
                    // setup Wouanda (TModeler) quand il tourne.
                    if (_isRestoring) ...[
                      const SizedBox(height: 16),
                      const AccountSetupProgress(fullScreen: false),
                    ],
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMd(
                          color: AppTheme.getTextPrimary(false),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _initializeApp(retry: true),
                        child: Text(lang.t('auth_retry')),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
