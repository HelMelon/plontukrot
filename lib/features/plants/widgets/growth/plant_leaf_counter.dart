import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';

class PlantLeafCounter extends StatelessWidget {
  final int count;
  final bool busy;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onScrollToStats;

  const PlantLeafCounter({
    super.key,
    required this.count,
    this.busy = false,
    this.onIncrement,
    this.onDecrement,
    this.onScrollToStats,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canDecrement = !busy && count > 0 && onDecrement != null;
    final canIncrement = !busy && onIncrement != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.dark1.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greenDeep.withValues(alpha: 0.8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundControl(
                  tooltip: l10n.plantLeafRemove,
                  icon: Icons.remove,
                  onPressed: canDecrement ? onDecrement : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '$count',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.heading,
                    ),
                  ),
                ),
                _RoundControl(
                  tooltip: l10n.plantLeafAdd,
                  icon: Icons.add,
                  onPressed: canIncrement ? onIncrement : null,
                ),
              ],
            ),
            if (onScrollToStats != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: onScrollToStats,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          l10n.plantLeafStatsAnchor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.goldAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_downward,
                        size: 16,
                        color: AppColors.goldAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _RoundControl({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.backgroundSecondary,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.greenDeep),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              color: onPressed == null
                  ? AppColors.textSecondary.withValues(alpha: 0.4)
                  : AppColors.goldAccent,
            ),
          ),
        ),
      ),
    );
  }
}
