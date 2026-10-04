import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/accessible_progress_indicator.dart';
import '../../../core/widgets/app_bar_chrome_actions.dart';
import '../../../core/widgets/app_modal.dart';
import '../../../models/experiment.dart';
import '../../../services/experiment_service.dart';
import 'experiment_details_page.dart';
import '../widgets/sheets/experiment_form_sheet.dart';

/// Hub for comparative experiments. Each card is a trial; opening one shows its
/// variants, participants and observation logs.
class ExperimentsPage extends StatefulWidget {
  const ExperimentsPage({super.key});

  @override
  State<ExperimentsPage> createState() => _ExperimentsPageState();
}

class _ExperimentsPageState extends State<ExperimentsPage> {
  final _service = ExperimentService();
  late final Stream<List<Experiment>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _service.watchExperiments();
  }

  Future<void> _openCreate() async {
    final created = await showAppModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExperimentFormSheet(),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).experimentsCreated)),
      );
    }
  }

  void _openDetails(Experiment experiment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExperimentDetailsPage(experimentId: experiment.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.screen,
      appBar: AppBar(
        backgroundColor: colors.screen,
        title: Text(l10n.experimentsTitle),
        actions: [
          IconButton(
            tooltip: l10n.experimentsAdd,
            onPressed: _openCreate,
            icon: Icon(context.icons.add, color: colors.icon),
          ),
          ...buildAppBarChromeActions(context),
        ],
      ),
      body: StreamBuilder<List<Experiment>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: SelectableText.rich(
                TextSpan(
                  text: l10n.commonError(snapshot.error.toString()),
                  style: TextStyle(color: colors.error),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: AccessibleProgressIndicator(color: colors.primary),
            );
          }
          final experiments = snapshot.data!;
          if (experiments.isEmpty) return _EmptyState(onCreate: _openCreate);
          return RefreshIndicator(
            onRefresh: () async => _stream.first,
            child: ListView.separated(
              padding: EdgeInsets.all(context.spacing.lg),
              itemCount: experiments.length,
              separatorBuilder: (_, __) => context.spacing.vMd,
              itemBuilder: (context, index) => _ExperimentCard(
                experiment: experiments[index],
                onTap: () => _openDetails(experiments[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: context.icons.experiments,
              size: 56,
              color: colors.icon,
            ),
            spacing.vLg,
            Text(
              l10n.experimentsNone,
              style: typography.titleMedium,
              textAlign: TextAlign.center,
            ),
            spacing.vSm,
            Text(
              l10n.experimentsNoneHint,
              style: typography.bodyLarge.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            spacing.vXl,
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(l10n.experimentsAdd),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperimentCard extends StatelessWidget {
  final Experiment experiment;
  final VoidCallback onTap;

  const _ExperimentCard({required this.experiment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final cards = context.components.cards;
    final typography = context.typography;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(cards.radius),
      child: Container(
        padding: cards.padding,
        decoration: cards.decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    experiment.title,
                    style: typography.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                spacing.hSm,
                _StatusChip(
                  label: experiment.isCompleted
                      ? l10n.experimentsStatusDone
                      : l10n.experimentsStatusActive,
                  isDone: experiment.isCompleted,
                ),
              ],
            ),
            if ((experiment.hypothesis ?? '').trim().isNotEmpty) ...[
              spacing.vXs,
              Text(
                experiment.hypothesis!,
                style:
                    typography.bodyMedium.copyWith(color: colors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            spacing.vSm,
            Text(
              '${l10n.experimentsVariantCount(experiment.variantCount)} · '
              '${l10n.experimentsObservationCount(experiment.observationCount)}',
              style: typography.bodySmall.copyWith(color: colors.icon),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isDone;

  const _StatusChip({required this.label, required this.isDone});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radii = context.radii;
    final typography = context.typography;
    final background = isDone ? colors.card : colors.primary;
    final foreground = isDone ? colors.textSecondary : colors.onPrimary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm,
        vertical: context.spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radii.pill),
        border: Border.all(color: colors.outline),
      ),
      child: Text(
        label,
        style: typography.captionSmall.copyWith(color: foreground),
      ),
    );
  }
}
