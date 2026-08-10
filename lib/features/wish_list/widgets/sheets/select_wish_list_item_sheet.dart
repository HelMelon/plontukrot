import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/wish_list_item.dart';
import '../../../../services/wish_list_service.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';

/// Picks a wish-list plant (e.g. after a propagation trade). No finance entry.
class SelectWishListItemSheet extends StatelessWidget {
  const SelectWishListItemSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final sheets = context.components.sheets;
    final typography = context.typography;
    final wishTheme = context.screens.wishList;
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.7;

    return Container(
      decoration: BoxDecoration(
        color: colors.modal,
        borderRadius: sheets.topBorderRadius,
      ),
      child: SafeArea(
        child: SizedBox(
          height: maxHeight,
          child: Padding(
            padding: sheets.contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: const SheetDragHandle()),
                spacing.vXxl,
                Text(
                  l10n.wishListSelectForTrade,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.titleLarge.copyWith(letterSpacing: -1),
                ),
                spacing.vXs,
                Text(
                  l10n.wishListSelectForTradeHint,
                  style: typography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                spacing.vXl,
                Expanded(
                  child: StreamBuilder<List<WishListItem>>(
                    stream: WishListService().watchItems(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: AccessibleProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(l10n.commonError('${snapshot.error}')),
                        );
                      }

                      final items = snapshot.data ?? const <WishListItem>[];
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.wishListEmpty,
                            textAlign: TextAlign.center,
                            style: typography.bodyLarge.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => spacing.vSm,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Material(
                            color: colors.card,
                            borderRadius:
                                BorderRadius.circular(wishTheme.cardRadius),
                            child: Semantics(
                              button: true,
                              label: '${item.nameAlt}. ${item.nameEn}',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                    wishTheme.cardRadius),
                                onTap: () => Navigator.pop(context, item),
                                child: Padding(
                                  padding: wishTheme.cardPadding,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.nameAlt,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: typography.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      spacing.vXxs,
                                      Text(
                                        item.nameEn,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: typography.bodyMedium.copyWith(
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                spacing.vMd,
                SizedBox(
                  width: double.infinity,
                  height: context.dimensions.buttonHeight,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.commonSkip),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
