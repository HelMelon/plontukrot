import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Bootstrap while Firebase and other startup work runs.
/// App logo centered + progress bar at the bottom.
class AppBootstrapPage extends StatefulWidget {
  final double progress;
  final String? statusText;

  const AppBootstrapPage({
    super.key,
    this.progress = 0,
    this.statusText,
  });

  static const logoPath = 'assets/images/app-icon.png';

  @override
  State<AppBootstrapPage> createState() => _AppBootstrapPageState();
}

class _AppBootstrapPageState extends State<AppBootstrapPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clamped = widget.progress.clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.dark1,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final side = min(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ) *
                          0.88;
                      return RotationTransition(
                        turns: _rotationController,
                        child: Image.asset(
                          AppBootstrapPage.logoPath,
                          width: side,
                          height: side,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              SizedBox(width: side, height: side),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (widget.statusText != null) ...[
                Text(
                  widget.statusText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: clamped <= 0 ? null : clamped,
                  minHeight: 8,
                  backgroundColor: AppColors.greenDeep,
                  color: AppColors.goldAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows splash-screen images in a shuffled order, each for [secondsPerImage].
class SplashCarouselPage extends StatefulWidget {
  final VoidCallback onFinished;
  final Duration secondsPerImage;

  const SplashCarouselPage({
    super.key,
    required this.onFinished,
    this.secondsPerImage = const Duration(milliseconds: 1100),
  });

  static const images = [
    'assets/images/splash-screen/splash-screen-1.png',
    'assets/images/splash-screen/splash-screen-2.png',
    'assets/images/splash-screen/splash-screen-3.png',
  ];

  @override
  State<SplashCarouselPage> createState() => _SplashCarouselPageState();
}

class _SplashCarouselPageState extends State<SplashCarouselPage> {
  late final List<String> _order;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _order = List<String>.from(SplashCarouselPage.images)..shuffle(Random());
    _scheduleNext();
  }

  void _scheduleNext() {
    Future<void>.delayed(widget.secondsPerImage, () {
      if (!mounted) return;
      if (_index >= _order.length - 1) {
        widget.onFinished();
        return;
      }
      setState(() => _index += 1);
      _scheduleNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark1,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        // contain: same framing for every splash, full art + text visible
        child: ColoredBox(
          key: ValueKey(_order[_index]),
          color: AppColors.dark1,
          child: SizedBox.expand(
            child: Image.asset(
              _order[_index],
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: AppColors.dark1),
            ),
          ),
        ),
      ),
    );
  }
}
