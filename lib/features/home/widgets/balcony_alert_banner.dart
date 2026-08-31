import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:plontukrot/services/api_client.dart';

/// A banner shown on the home screen when the balcony temperature has dropped
/// below a plant's cold-tolerance threshold and it needs bringing inside.
///
/// Reads `GET /balcony/status` (JWT-protected). Hidden when the feature is
/// out of season (summer) or when nothing needs bringing in.
class BalconyAlertBanner extends StatefulWidget {
  const BalconyAlertBanner({super.key});

  @override
  State<BalconyAlertBanner> createState() => _BalconyAlertBannerState();
}

class _BalconyAlertBannerState extends State<BalconyAlertBanner> {
  List<Map<String, dynamic>> _needsInside = const [];
  double? _temperature;
  bool _loading = true;
  bool _active = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    // Refresh periodically so the banner updates as the temperature changes.
    _timer = Timer.periodic(const Duration(minutes: 15), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.get('/balcony/status');
      if (!mounted) return;
      final map = res is Map ? Map<String, dynamic>.from(res) : null;
      final needs = map?['needs_inside'];
      setState(() {
        _active = map?['active'] == true;
        _temperature = (map?['temperature'] as num?)?.toDouble();
        _needsInside = needs is List
            ? needs.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : const [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_active || _needsInside.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final names = _needsInside.map((n) => n['name'] ?? '').where((n) => n.isNotEmpty).join(', ');
    final temp = _temperature;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: spacing.md),
      padding: EdgeInsets.all(spacing.sm),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.radii.md),
        border: Border.all(color: colors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.ac_unit, color: colors.error, size: context.dimensions.iconLg),
          spacing.hSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  temp != null
                      ? l10n.balconyAlertTitle(temp)
                      : l10n.balconyAlertTitleNoTemp,
                  style: typography.bodyEmphasis.copyWith(color: colors.error),
                ),
                if (names.isNotEmpty) ...[
                  spacing.vXxs,
                  Text(
                    names,
                    style: typography.bodySmall.copyWith(color: colors.textPrimary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
