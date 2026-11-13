import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:ngoma/core/i18n/translations.dart';
import 'package:ngoma/core/router.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/features/messaging/messaging.dart';
import 'package:ngoma/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('fr', null);
    await initializeDateFormatting('en', null);
    Intl.defaultLocale = 'fr';
  } catch (_) {
    // Widgets can still start with the platform locale if locale data is absent.
  }
  runApp(const ProviderScope(child: WouandaApp()));
}

class WouandaApp extends ConsumerWidget {
  const WouandaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    return MaterialApp.router(
      title: 'Wouanda Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: Locale(currentLanguage.code),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MessagingHost(
        onOpenConversation: (id) =>
            router.push('/messages/${Uri.encodeComponent(id.toString())}'),
        child: IncomingCallHost(
          navigatorKey: rootNavigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
