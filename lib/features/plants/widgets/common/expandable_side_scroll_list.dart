import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';

/// Collapsed: first [collapsedVisible] items as a vertical list.
/// Expanded: same vertical list, viewport fits ~[expandedViewport] items;
/// the rest scroll with a scrollbar on the right.
class ExpandableSideScrollList extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int collapsedVisible;
  final int expandedViewport;

  /// Approximate height of one row (used to size the expanded viewport).
  final double itemExtent;

  const ExpandableSideScrollList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.collapsedVisible = 3,
    this.expandedViewport = 5,
    this.itemExtent = 96,
  });

  @override
  State<ExpandableSideScrollList> createState() =>
      _ExpandableSideScrollListState();
}

class _ExpandableSideScrollListState extends State<ExpandableSideScrollList> {
  bool _expanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final count = widget.itemCount;
    if (count <= 0) return const SizedBox.shrink();

    final canExpand = count > widget.collapsedVisible;
    final showExpanded = _expanded && canExpand;
    final collapsedCount =
        count < widget.collapsedVisible ? count : widget.collapsedVisible;
    final viewport =
        widget.expandedViewport < 1 ? 1 : widget.expandedViewport;
    final listHeight = widget.itemExtent * viewport;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!showExpanded)
          for (var index = 0; index < collapsedCount; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == collapsedCount - 1 ? 0 : spacing.sm,
              ),
              child: widget.itemBuilder(context, index),
            )
        else
          SizedBox(
            height: listHeight,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: count > viewport,
              child: ListView.separated(
                controller: _scrollController,
                padding: EdgeInsets.only(right: spacing.sm),
                itemCount: count,
                separatorBuilder: (_, __) => spacing.vSm,
                itemBuilder: widget.itemBuilder,
              ),
            ),
          ),
        if (canExpand) ...[
          spacing.vXxs,
          Center(
            child: IconButton(
              tooltip:
                  showExpanded ? l10n.commonCollapse : l10n.commonShowMore,
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                showExpanded
                    ? context.icons.chevronUp
                    : context.icons.chevronDown,
                color: context.colors.primary,
                size: spacing.xxl,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
