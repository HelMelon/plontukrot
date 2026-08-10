import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/accessible_progress_indicator.dart';
import '../../../core/widgets/app_modal.dart';
import '../../../models/finance_entry.dart';
import '../../plants/widgets/common/plant_network_image.dart';

/// Opens a full-screen-ish dialog and only then loads receipt image(s).
Future<void> showFinanceReceiptsViewer(
  BuildContext context, {
  required List<FinanceReceipt> receipts,
}) {
  final valid = receipts.where((r) => r.isValid).toList(growable: false);
  if (valid.isEmpty) return Future.value();

  return showAppDialog<void>(
    context: context,
    builder: (dialogContext) => _FinanceReceiptsViewerDialog(receipts: valid),
  );
}

class _FinanceReceiptsViewerDialog extends StatefulWidget {
  final List<FinanceReceipt> receipts;

  const _FinanceReceiptsViewerDialog({required this.receipts});

  @override
  State<_FinanceReceiptsViewerDialog> createState() =>
      _FinanceReceiptsViewerDialogState();
}

class _FinanceReceiptsViewerDialogState
    extends State<_FinanceReceiptsViewerDialog> {
  late final PageController _pageController;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final dimensions = context.dimensions;
    final count = widget.receipts.length;

    return Dialog(
      backgroundColor: colors.modal,
      insetPadding: EdgeInsets.all(spacing.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.md,
                spacing.sm,
                spacing.xs,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      count > 1
                          ? l10n.financesReceiptViewerTitlePaged(
                              _index + 1,
                              count,
                            )
                          : l10n.financesReceiptViewerTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.titleSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.commonClose,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: count,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    final receipt = widget.receipts[index];
                    final placeholder = Center(
                      child: AccessibleProgressIndicator(
                        color: colors.primary,
                      ),
                    );
                    final error = Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: colors.icon,
                        size: dimensions.iconXl,
                      ),
                    );
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: PlantNetworkImage(
                        imageUrl: receipt.url,
                        fit: BoxFit.contain,
                        semanticLabel: l10n.financesReceiptImageLabel(
                          index + 1,
                        ),
                        placeholder: placeholder,
                        errorWidget: error,
                      ),
                    );
                  },
                ),
              ),
            ),
            if (count > 1)
              Padding(
                padding: EdgeInsets.only(bottom: spacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(count, (i) {
                    final selected = i == _index;
                    return Container(
                      width: spacing.sm,
                      height: spacing.sm,
                      margin: EdgeInsets.symmetric(horizontal: spacing.xxs),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? colors.primary
                            : colors.outline,
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
