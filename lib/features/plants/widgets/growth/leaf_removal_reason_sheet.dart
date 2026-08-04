import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/growth_event.dart';

Future<LeafRemovalReason?> showLeafRemovalReasonSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<LeafRemovalReason>(
    context: context,
    backgroundColor: AppColors.backgroundSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.plantLeafRemoveTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.content_cut,
                    color: AppColors.goldAccent),
                title: Text(l10n.plantLeafRemoveCut),
                onTap: () =>
                    Navigator.pop(context, LeafRemovalReason.cutForRooting),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restaurant,
                    color: AppColors.goldAccent),
                title: Text(l10n.plantLeafRemoveEaten),
                onTap: () => Navigator.pop(context, LeafRemovalReason.eaten),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.water_drop_outlined,
                    color: AppColors.goldAccent),
                title: Text(l10n.plantLeafRemoveDried),
                onTap: () => Navigator.pop(context, LeafRemovalReason.dried),
              ),
            ],
          ),
        ),
      );
    },
  );
}
