import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import 'core/locale/app_locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/pages/login_page.dart';
import 'features/home/pages/home_page.dart';
import 'features/splash/pages/splash_flow.dart';
import 'firebase_options.dart';
import 'models/app_user.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocaleController.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocaleController.instance,
      builder: (context, _) {
        final localeOverride = AppLocaleController.instance.localeOverride;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          locale: localeOverride,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: AppLocaleController.resolveLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  repeat: ImageRepeat.repeat,
                  fit: BoxFit.contain,
                ),
              ),
              child: child,
            );
          },
          home: const AppStartup(),
        );
      },
    );
  }
}

enum _StartupPhase { bootstrap, splash, ready }

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  _StartupPhase _phase = _StartupPhase.bootstrap;
  double _progress = 0;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final override = AppLocaleController.instance.localeOverride;
      final device = WidgetsBinding.instance.platformDispatcher.locale;
      final resolved = AppLocaleController.resolveLocale(
            override ?? device,
            AppLocalizations.supportedLocales,
          ) ??
          const Locale('en');
      final l10n = lookupAppLocalizations(resolved);

      setState(() {
        _progress = 0.15;
        _statusText = l10n.loading;
      });

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (!mounted) return;
      setState(() {
        _progress = 0.65;
        _statusText = l10n.preparing;
      });

      await initializeDateFormatting(resolved.languageCode);
      Intl.defaultLocale = resolved.languageCode;
      if (!mounted) return;
      setState(() {
        _progress = 1;
        _statusText = null;
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() => _phase = _StartupPhase.splash);
    } catch (_) {
      if (!mounted) return;
      setState(() => _phase = _StartupPhase.splash);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _StartupPhase.bootstrap:
        return AppBootstrapPage(
          progress: _progress,
          statusText: _statusText,
        );
      case _StartupPhase.splash:
        return SplashCarouselPage(
          onFinished: () {
            if (!mounted) return;
            setState(() => _phase = _StartupPhase.ready);
          },
        );
      case _StartupPhase.ready:
        return const AuthGate();
    }
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService().watchAuthState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return HomePage(user: snapshot.data!);
        }

        return const LoginPage();
      },
    );
  }
}
