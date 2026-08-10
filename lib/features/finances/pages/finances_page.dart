import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/currency/app_currency_controller.dart';
import '../../../core/theme/theme_context.dart';
import '../../../models/finance_entry.dart';
import '../../../services/finance_service.dart';
import '../widgets/sheets/add_finance_entry_sheet.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';

class FinancesPage extends StatefulWidget {
  const FinancesPage({super.key});

  @override
  State<FinancesPage> createState() => _FinancesPageState();
}

class _FinancesPageState extends State<FinancesPage> {
  late final FinanceService _service;
  late final Stream<List<FinanceEntry>> _entriesStream;

  @override
  void initState() {
    super.initState();
    _service = FinanceService();
    _entriesStream = _service.watchEntries();
  }

  Future<void> _openSheet({
    FinanceEntry? entry,
    FinanceEntryType type = FinanceEntryType.expense,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (_) => entry == null
          ? AddFinanceEntrySheet(initialType: type)
          : AddFinanceEntrySheet.edit(entry: entry),
    );
  }

  Future<void> _confirmDelete(FinanceEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.commonDelete),
          content: Text(l10n.financesDeleteConfirm(entry.title)),
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
      await _service.deleteEntry(entry.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    }
  }

  Widget _analyticsCard(List<FinanceEntry> entries) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final theme = context.screens.finances;
    final currency = AppCurrencyController.instance;
    final summaries = _service.summarizeLastMonths(entries);
    final totalIncome =
        summaries.fold<double>(0, (sum, item) => sum + item.income);
    final totalExpense =
        summaries.fold<double>(0, (sum, item) => sum + item.expense);
    final balance = totalIncome - totalExpense;
    final monthFormat = DateFormat.MMM();

    return Container(
      width: double.infinity,
      padding: theme.analyticsPadding,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(theme.analyticsRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.financesAnalyticsTitle,
            style: typography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          spacing.vMd,
          Row(
            children: [
              Expanded(
                child: _metric(
                  label: l10n.financesIncome,
                  value: currency.format(totalIncome),
                  color: colors.primary,
                ),
              ),
              spacing.hSm,
              Expanded(
                child: _metric(
                  label: l10n.financesExpense,
                  value: currency.format(totalExpense),
                  color: colors.error,
                ),
              ),
              spacing.hSm,
              Expanded(
                child: _metric(
                  label: l10n.financesBalance,
                  value: currency.format(balance),
                  color: balance >= 0 ? colors.primary : colors.error,
                ),
              ),
            ],
          ),
          spacing.vLg,
          for (final summary in summaries.reversed) ...[
            Row(
              children: [
                SizedBox(
                  width: spacing.xxl + spacing.md,
                  child: Text(
                    monthFormat.format(summary.month),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '+${currency.format(summary.income)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodySmall.copyWith(color: colors.primary),
                  ),
                ),
                Expanded(
                  child: Text(
                    '-${currency.format(summary.expense)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: typography.bodySmall.copyWith(color: colors.error),
                  ),
                ),
              ],
            ),
            if (summary != summaries.first) spacing.vXs,
          ],
        ],
      ),
    );
  }

  Widget _metric({
    required String label,
    required String value,
    required Color color,
  }) {
    final typography = context.typography;
    final colors = context.colors;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography.bodySmall.copyWith(color: colors.textSecondary),
        ),
        spacing.vXxs,
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography.bodyLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, VoidCallback onAdd) {
    final typography = context.typography;
    final dimensions = context.dimensions;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          width: dimensions.buttonHeight,
          height: dimensions.buttonHeight,
          child: FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(dimensions.buttonHeight, dimensions.buttonHeight),
              maximumSize: Size(dimensions.buttonHeight, dimensions.buttonHeight),
            ),
            child: Icon(Icons.add, size: dimensions.iconXl),
          ),
        ),
      ],
    );
  }

  Widget _entryTile(FinanceEntry entry) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final theme = context.screens.finances;
    final currency = AppCurrencyController.instance;
    final sign = entry.isIncome ? '+' : '-';
    final amountColor = entry.isIncome ? colors.primary : colors.error;

    return Container(
      padding: theme.cardPadding,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(theme.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                spacing.vXxs,
                Text(
                  DateFormat('d MMM y').format(entry.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                spacing.vXxs,
                Text(
                  '$sign${currency.format(entry.amount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.bodyLarge.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.commonEdit,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openSheet(entry: entry),
          ),
          IconButton(
            tooltip: l10n.commonDelete,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(entry),
          ),
        ],
      ),
    );
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
              icon: HugeIcons.strokeRoundedCoins01,
              color: colors.icon,
              size: dimensions.iconXl,
            ),
            spacing.vMd,
            Text(
              l10n.financesEmpty,
              textAlign: TextAlign.center,
              style: typography.bodyLarge.copyWith(color: colors.textSecondary),
            ),
            spacing.vXs,
            Text(
              l10n.financesEmptyHint,
              textAlign: TextAlign.center,
              style: typography.bodyMedium.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;

    return ListenableBuilder(
      listenable: AppCurrencyController.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(l10n.financesTitle),
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: l10n.financesAdd,
            onPressed: () => _openSheet(),
            child: const Icon(Icons.add),
          ),
          body: StreamBuilder<List<FinanceEntry>>(
            stream: _entriesStream,
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

              final entries = snapshot.data ?? const <FinanceEntry>[];
              final incomes =
                  entries.where((e) => e.isIncome).toList(growable: false);
              final expenses =
                  entries.where((e) => e.isExpense).toList(growable: false);

              if (entries.isEmpty) {
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    spacing.md,
                    spacing.sm,
                    spacing.md,
                    spacing.xxl * 2,
                  ),
                  children: [
                    _analyticsCard(entries),
                    spacing.vXxl,
                    _emptyState(l10n),
                  ],
                );
              }

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  spacing.md,
                  spacing.sm,
                  spacing.md,
                  spacing.xxl * 2,
                ),
                children: [
                  _analyticsCard(entries),
                  spacing.vXxl,
                  _sectionHeader(
                    l10n.financesIncome,
                    () => _openSheet(type: FinanceEntryType.income),
                  ),
                  spacing.vSm,
                  if (incomes.isEmpty)
                    Text(
                      l10n.financesNoIncome,
                      style: context.typography.bodyMedium.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    )
                  else
                    for (var i = 0; i < incomes.length; i++) ...[
                      _entryTile(incomes[i]),
                      if (i != incomes.length - 1) spacing.vSm,
                    ],
                  spacing.vXxl,
                  _sectionHeader(
                    l10n.financesExpense,
                    () => _openSheet(type: FinanceEntryType.expense),
                  ),
                  spacing.vSm,
                  if (expenses.isEmpty)
                    Text(
                      l10n.financesNoExpense,
                      style: context.typography.bodyMedium.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    )
                  else
                    for (var i = 0; i < expenses.length; i++) ...[
                      _entryTile(expenses[i]),
                      if (i != expenses.length - 1) spacing.vSm,
                    ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}
