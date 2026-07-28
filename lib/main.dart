import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/pages/login_page.dart';
import 'features/home/pages/home_page.dart';
import 'features/splash/pages/splash_flow.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('ru'),
      supportedLocales: const [
        Locale('ru'),
        Locale('en'),
      ],
      localizationsDelegates: const [
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
      setState(() {
        _progress = 0.15;
        _statusText = 'Загрузка…';
      });

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (!mounted) return;
      setState(() {
        _progress = 0.65;
        _statusText = 'Подготовка…';
      });

      await initializeDateFormatting('ru');
      Intl.defaultLocale = 'ru';
      if (!mounted) return;
      setState(() {
        _progress = 1;
        _statusText = null;
      });

      await Future<void>.delayed(const Duration(milliseconds: 200));
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return HomePage(user: snapshot.data!);
        }

        return const LoginPage();
      },
    );
  }
}
