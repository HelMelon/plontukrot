import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import 'core/currency/app_currency_controller.dart';
import 'core/keyboard/app_keyboard.dart';
import 'core/locale/app_locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_context.dart';
import 'features/auth/pages/email_verification_page.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/personal_data_consent_gate_page.dart';
import 'features/home/pages/home_page.dart';
import 'features/splash/pages/splash_flow.dart';
import 'firebase_options.dart';
import 'models/app_user.dart';
import 'services/app_crash_reporting.dart';
import 'services/auth_service.dart';
import 'services/gift_service.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  await AppLocaleController.instance.load();
  await AppCurrencyController.instance.load();
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
          theme: AppTheme.theme,
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
            final width = MediaQuery.sizeOf(context).width;
            return Theme(
              data: AppTheme.themeForWidth(width),
              child: AppKeyboardScope(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const _AppTiledBackground(),
                    if (child != null) child,
                  ],
                ),
              ),
            );
          },
          home: const AppStartup(),
        );
      },
    );
  }
}

/// Global wallpaper under every route. Decoded at a capped width and precached
/// so secondary pages do not flash an opaque scaffold while the tile resolves.
class _AppTiledBackground extends StatefulWidget {
  const _AppTiledBackground();

  @override
  State<_AppTiledBackground> createState() => _AppTiledBackgroundState();
}

class _AppTiledBackgroundState extends State<_AppTiledBackground> {
  static const AssetImage _asset =
      AssetImage('assets/images/background.webp');

  /// Source is 1536×1024 (~200KB); cap decode for cheaper tiling on large DPI.
  static final ImageProvider _image = ResizeImage(_asset, width: 1024);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(precacheImage(_image, context));
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: _image,
            repeat: ImageRepeat.repeat,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.low,
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

enum _StartupPhase { bootstrap, app }

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  _StartupPhase _phase = _StartupPhase.bootstrap;
  double _progress = 0;
  String? _statusText;

  /// Completes when Login / consent / Home first content is painted under splash.
  final Completer<void> _contentReady = Completer<void>();
  bool _splashDismissed = false;

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
      await AppCrashReporting.instance.install();
      await AppCrashReporting.instance.setUserId(
        AuthService().currentUser?.uid,
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
      setState(() => _phase = _StartupPhase.app);
    } catch (error, stack) {
      await AppCrashReporting.instance.recordError(
        error,
        stack,
        reason: 'app_bootstrap_failed',
      );
      if (!mounted) return;
      setState(() => _phase = _StartupPhase.app);
    }
  }

  void _onContentReady() {
    if (!_contentReady.isCompleted) {
      _contentReady.complete();
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
      case _StartupPhase.app:
        // Build the real app under the splash so streams, images, and the first
        // Home frame happen while art is visible — then reveal.
        return Stack(
          fit: StackFit.expand,
          children: [
            AuthGate(onContentReady: _onContentReady),
            if (!_splashDismissed)
              Positioned.fill(
                child: SplashCarouselPage(
                  secondsPerImage: const Duration(milliseconds: 1600),
                  waitFor: _contentReady.future.timeout(
                    const Duration(seconds: 20),
                    onTimeout: () {
                      unawaited(
                        AppCrashReporting.instance.recordError(
                          TimeoutException('home_content_ready'),
                          StackTrace.current,
                          reason: 'splash_home_ready_timeout',
                        ),
                      );
                    },
                  ),
                  onFinished: () {
                    if (!mounted) return;
                    setState(() => _splashDismissed = true);
                  },
                ),
              ),
          ],
        );
    }
  }
}

class AuthGate extends StatelessWidget {
  final VoidCallback? onContentReady;

  const AuthGate({super.key, this.onContentReady});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<AppUser?>(
      stream: auth.watchAuthState(),
      initialData: auth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data ?? auth.currentUser;
        final waiting = snapshot.connectionState == ConnectionState.waiting &&
            user == null;

        if (waiting) {
          // Covered by splash during cold start; avoid a visible spinner.
          if (onContentReady != null) {
            return const SizedBox.expand();
          }
          final colors = context.colors;
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: AccessibleProgressIndicator(color: colors.primary),
            ),
          );
        }

        if (user != null) {
          unawaited(AppCrashReporting.instance.setUserId(user.uid));
          if (auth.needsEmailVerification) {
            return EmailVerificationPage(onContentReady: onContentReady);
          }
          return _AuthenticatedShell(
            user: user,
            onContentReady: onContentReady,
          );
        }

        unawaited(AppCrashReporting.instance.setUserId(null));
        return _ReadyAfterFrame(
          onReady: onContentReady,
          child: const LoginPage(),
        );
      },
    );
  }
}

/// Fires [onReady] once after the first frame of [child].
class _ReadyAfterFrame extends StatefulWidget {
  final Widget child;
  final VoidCallback? onReady;

  const _ReadyAfterFrame({required this.child, this.onReady});

  @override
  State<_ReadyAfterFrame> createState() => _ReadyAfterFrameState();
}

class _ReadyAfterFrameState extends State<_ReadyAfterFrame> {
  @override
  void initState() {
    super.initState();
    if (widget.onReady == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onReady?.call();
      });
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Syncs locale/currency from Firestore once the user is signed in.
class _AuthenticatedShell extends StatefulWidget {
  final AppUser user;
  final VoidCallback? onContentReady;

  const _AuthenticatedShell({
    required this.user,
    this.onContentReady,
  });

  @override
  State<_AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<_AuthenticatedShell> {
  @override
  void initState() {
    super.initState();
    _syncPreferences();
    unawaited(GiftService().processAcceptedOutgoingGifts());
  }

  @override
  void didUpdateWidget(covariant _AuthenticatedShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _syncPreferences();
      unawaited(GiftService().processAcceptedOutgoingGifts());
    }
  }

  Future<void> _syncPreferences() async {
    await AppLocaleController.instance.syncWithCloud();
    await AppCurrencyController.instance.syncWithCloud();
  }

  @override
  Widget build(BuildContext context) {
    return PersonalDataConsentGatePage(
      onContentReady: widget.onContentReady,
      child: HomePage(
        user: widget.user,
        onFirstContentReady: widget.onContentReady,
      ),
    );
  }
}
