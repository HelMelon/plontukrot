import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import 'package:plontukrot/core/theme/theme_context.dart';

import '../../../models/wish_list_item.dart';
import '../../../services/wish_list_service.dart';
import '../widgets/sheets/add_wish_list_item_sheet.dart';
import '../widgets/sheets/wish_list_acquire_sheet.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/app_bar_chrome_actions.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';

class WishListPage extends StatefulWidget {
  const WishListPage({super.key});

  @override
  State<WishListPage> createState() => _WishListPageState();
}

class _WishListPageState extends State<WishListPage> {
  late final WishListService _service;
  late final Stream<List<WishListItem>> _itemsStream;
  List<WishListItem> _latestItems = const [];
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _service = WishListService();
    _itemsStream = _service.watchItems();
  }

  Future<void> _openAddSheet({WishListItem? item}) async {
    await showAppModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (_) => item == null
          ? const AddWishListItemSheet()
          : AddWishListItemSheet.edit(item: item),
    );
  }

  Future<void> _confirmDelete(WishListItem item) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.commonDelete),
          content: Text(l10n.wishListDeleteConfirm(item.nameAlt)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.commonDelete),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteItem(item.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    }
  }

  Future<void> _openBoughtSheet(WishListItem item) async {
    await openWishListAcquireFlow(context, item);
  }

  Future<void> _exportList() async {
    final l10n = AppLocalizations.of(context);
    if (_latestItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.wishListExportEmpty)),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final dateStamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'wish-list-$dateStamp.txt';
      final lines = _latestItems
          .map((item) => '${item.nameAlt} | ${item.nameEn}')
          .join('\n');
      final bytes = utf8.encode('$lines\n');

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'text/plain',
              name: fileName,
            ),
          ],
          fileNameOverrides: [fileName],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Widget _emptyState(AppLocalizations l10n) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final dimensions = context.dimensions;
    final homeTheme = context.screens.home;

    return Center(
      child: Padding(
        padding: homeTheme.emptyStatePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: context.icons.wishlist,
              color: colors.icon,
              size: dimensions.iconXl,
            ),
            spacing.vMd,
            Text(
              l10n.wishListEmpty,
              textAlign: TextAlign.center,
              style: typography.bodyLarge.copyWith(
                color: colors.textSecondary,
              ),
            ),
            spacing.vXs,
            Text(
              l10n.wishListEmptyHint,
              textAlign: TextAlign.center,
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemTile(WishListItem item) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final wishTheme = context.screens.wishList;

    return Container(
      padding: wishTheme.cardPadding,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(wishTheme.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                spacing.vSm,
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _openBoughtSheet(item),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.symmetric(horizontal: spacing.sm),
                    ),
                    child: Text(l10n.wishListBought),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.commonEdit,
            visualDensity: VisualDensity.compact,
            icon: Icon(context.icons.editOutlined),
            onPressed: () => _openAddSheet(item: item),
          ),
          IconButton(
            tooltip: l10n.commonDelete,
            visualDensity: VisualDensity.compact,
            icon: Icon(context.icons.delete),
            onPressed: () => _confirmDelete(item),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final dimensions = context.dimensions;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.wishListTitle),
        actions: [
          IconButton(
            tooltip: l10n.wishListExport,
            onPressed: _isExporting ? null : _exportList,
            icon: _isExporting
                ? SizedBox(
                    width: dimensions.iconSm,
                    height: dimensions.iconSm,
                    child: AccessibleProgressIndicator(strokeWidth: 2, color: colors.icon),
                  )
                : Icon(context.icons.share, color: colors.icon),
          ),
          ...buildAppBarChromeActions(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.wishListAdd,
        onPressed: () => _openAddSheet(),
        child: Icon(context.icons.add),
      ),
      body: StreamBuilder<List<WishListItem>>(
        stream: _itemsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: AccessibleProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: spacing.allLg,
                child: Text(
                  l10n.commonError(snapshot.error.toString()),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final items = snapshot.data ?? const <WishListItem>[];
          _latestItems = items;

          if (items.isEmpty) {
            return _emptyState(l10n);
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              spacing.md,
              spacing.sm,
              spacing.md,
              spacing.xxl * 2,
            ),
            itemCount: items.length,
            separatorBuilder: (_, __) => spacing.vSm,
            itemBuilder: (context, index) => _itemTile(items[index]),
          );
        },
      ),
    );
  }
}
