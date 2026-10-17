import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/accessible_progress_indicator.dart';
import '../../../core/widgets/app_bar_chrome_actions.dart';
import '../../../core/widgets/app_modal.dart';
import '../../../models/experiment.dart';
import '../../../models/experiment_observation.dart';
import '../../../models/experiment_subject.dart';
import '../../../models/experiment_variant.dart';
import '../../../services/experiment_service.dart';
import '../../plants/widgets/common/plant_image.dart';
import '../widgets/sheets/add_observation_sheet.dart';
import '../widgets/sheets/add_subjects_sheet.dart';
import '../widgets/sheets/experiment_compare_sheet.dart';
import '../widgets/sheets/experiment_form_sheet.dart';

/// One experiment: header, per-variant participants, and each participant's
/// observation log. Every mutation writes to the backend and the poll stream
/// refreshes the page, so no local state is kept for server data.
class ExperimentDetailsPage extends StatefulWidget {
  final String experimentId;

  const ExperimentDetailsPage({super.key, required this.experimentId});

  @override
  State<ExperimentDetailsPage> createState() => _ExperimentDetailsPageState();
}

class _ExperimentDetailsPageState extends State<ExperimentDetailsPage> {
  final _service = ExperimentService();
  late final Stream<Experiment?> _stream;

  @override
  void initState() {
    super.initState();
    // One stream per page lifetime: building a new poll stream on every rebuild
    // would spin up an extra poller each time.
    _stream = _service.watchExperiment(widget.experimentId);
  }

  Future<void> _openEdit(Experiment experiment) async {
    await showAppModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExperimentFormSheet(experiment: experiment),
    );
  }

  Future<void> _openCompare(Experiment experiment) {
    return showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExperimentCompareSheet(experiment: experiment),
    );
  }

  Future<void> _toggleComplete(Experiment experiment) async {
    final l10n = AppLocalizations.of(context);
    try {
      if (experiment.isCompleted) {
        await _service.updateExperiment(
          experimentId: experiment.id,
          clearCompletedAt: true,
        );
      } else {
        await _service.updateExperiment(
          experimentId: experiment.id,
          completedAt: DateTime.now(),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(error.toString()))),
      );
    }
  }

  Future<void> _addSubjects(ExperimentVariant variant) async {
    final existing = variant.subjects
        .map((subject) => '${subject.subjectType.code}:${subject.subjectId}')
        .toSet();
    await showAppModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSubjectsSheet(
        variantId: variant.id,
        existingSubjectIds: existing,
      ),
    );
  }

  Future<void> _addObservation(ExperimentSubject subject) async {
    await showAppModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddObservationSheet(subject: subject),
    );
  }

  Future<void> _editObservation(
    ExperimentSubject subject,
    ExperimentObservation observation,
  ) async {
    await showAppModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddObservationSheet(
        subject: subject,
        observation: observation,
      ),
    );
  }

  Future<void> _deleteObservation(ExperimentObservation observation) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(l10n.experimentsDeletedObservation);
    if (confirmed != true) return;
    try {
      await _service.deleteObservation(observation.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(error.toString()))),
      );
    }
  }

  Future<void> _removeSubject(ExperimentSubject subject) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(l10n.experimentsDeletedSubject);
    if (confirmed != true) return;
    try {
      await _service.deleteSubject(subject.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(error.toString()))),
      );
    }
  }

  Future<void> _deleteExperiment(Experiment experiment) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.commonDelete),
        content: Text(l10n.experimentsDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteExperiment(experiment.id);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(error.toString()))),
      );
    }
  }

  Future<bool?> _confirm(String message) {
    final l10n = AppLocalizations.of(context);
    return showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return StreamBuilder<Experiment?>(
      stream: _stream,
      builder: (context, snapshot) {
        final experiment = snapshot.data;
        return Scaffold(
          backgroundColor: colors.screen,
          appBar: AppBar(
            backgroundColor: colors.screen,
            title: Text(
              experiment?.title ?? l10n.experimentsTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (experiment != null) ...[
                IconButton(
                  tooltip: l10n.experimentsCompare,
                  onPressed: experiment.comparableVariants.isEmpty
                      ? null
                      : () => _openCompare(experiment),
                  icon: HugeIcon(
                    icon: context.icons.experiments,
                    color: colors.icon,
                  ),
                ),
                IconButton(
                  tooltip: l10n.experimentsEditTitle,
                  onPressed: () => _openEdit(experiment),
                  icon: Icon(context.icons.edit, color: colors.icon),
                ),
              ],
              ...buildAppBarChromeActions(context),
            ],
          ),
          body: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<Experiment?> snapshot) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
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
      return Center(child: AccessibleProgressIndicator(color: colors.primary));
    }
    final experiment = snapshot.data;
    if (experiment == null) {
      return Center(
        child: SelectableText.rich(
          TextSpan(
            text: l10n.experimentsEmpty,
            style: TextStyle(color: colors.error),
          ),
        ),
      );
    }

    final spacing = context.spacing;
    return ListView(
      padding: EdgeInsets.all(spacing.lg),
      children: [
        _HeaderCard(
          experiment: experiment,
          onToggleComplete: () => _toggleComplete(experiment),
          onCompare: () => _openCompare(experiment),
          onDelete: () => _deleteExperiment(experiment),
        ),
        spacing.vLg,
        for (final variant in experiment.variants) ...[
          _VariantCard(
            variant: variant,
            experimentStartedAt: experiment.startedAt,
            onAddSubjects: () => _addSubjects(variant),
            onAddObservation: _addObservation,
            onEditObservation: _editObservation,
            onDeleteObservation: _deleteObservation,
            onRemoveSubject: _removeSubject,
          ),
          spacing.vMd,
        ],
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Experiment experiment;
  final VoidCallback onToggleComplete;
  final VoidCallback onCompare;
  final VoidCallback onDelete;

  const _HeaderCard({
    required this.experiment,
    required this.onToggleComplete,
    required this.onCompare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final cards = context.components.cards;
    final dateFormat = DateFormat('d MMM y');
    final startedAt = experiment.startedAt;

    return Container(
      padding: cards.padding,
      decoration: cards.decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((experiment.hypothesis ?? '').trim().isNotEmpty) ...[
            _Labelled(
              label: l10n.experimentsAddHypothesis,
              value: experiment.hypothesis!,
            ),
            spacing.vSm,
          ],
          if (startedAt != null)
            _Labelled(
              label: l10n.experimentsStartedAt,
              value:
                  '${dateFormat.format(startedAt)} · ${l10n.experimentsDays(experiment.daysSinceStart)}',
            ),
          if ((experiment.note ?? '').trim().isNotEmpty) ...[
            spacing.vSm,
            _Labelled(
              label: l10n.experimentsFieldNote,
              value: experiment.note!,
            ),
          ],
          if ((experiment.conclusion ?? '').trim().isNotEmpty) ...[
            spacing.vSm,
            _Labelled(
              label: l10n.experimentsConclusion,
              value: experiment.conclusion!,
            ),
          ],
          spacing.vMd,
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggleComplete,
                  icon: Icon(
                    experiment.isCompleted
                        ? Icons.refresh
                        : Icons.check_circle_outline,
                  ),
                  label: Text(
                    experiment.isCompleted
                        ? l10n.experimentsReopen
                        : l10n.experimentsComplete,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              spacing.hSm,
              Semantics(
                button: true,
                label: l10n.commonDelete,
                child: IconButton(
                  onPressed: onDelete,
                  tooltip: l10n.commonDelete,
                  icon: Icon(context.icons.delete, color: colors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Labelled extends StatelessWidget {
  final String label;
  final String value;

  const _Labelled({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typography.captionSmall.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        context.spacing.vXs,
        SelectableText(
          value,
          style: context.typography.bodyLarge,
        ),
      ],
    );
  }
}

class _VariantCard extends StatelessWidget {
  final ExperimentVariant variant;
  final DateTime? experimentStartedAt;
  final VoidCallback onAddSubjects;
  final Future<void> Function(ExperimentSubject) onAddObservation;
  final Future<void> Function(ExperimentSubject, ExperimentObservation)
      onEditObservation;
  final Future<void> Function(ExperimentObservation) onDeleteObservation;
  final Future<void> Function(ExperimentSubject) onRemoveSubject;

  const _VariantCard({
    required this.variant,
    required this.experimentStartedAt,
    required this.onAddSubjects,
    required this.onAddObservation,
    required this.onEditObservation,
    required this.onDeleteObservation,
    required this.onRemoveSubject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final cards = context.components.cards;
    final typography = context.typography;

    return Container(
      padding: cards.padding,
      decoration: cards.decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  variant.label,
                  style: typography.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if ((variant.imageUrl ?? '').trim().isNotEmpty) ...[
            spacing.vSm,
            ClipRRect(
              borderRadius: context.radii.mdAll,
              child: PlantImage(
                imageUrl: variant.imageUrl,
                width: double.infinity,
                height: context.dimensions.photoPreview,
                fit: BoxFit.cover,
                semanticLabel: l10n.experimentsVariantPhotoOf(variant.label),
                placeholder: SizedBox(
                  width: double.infinity,
                  height: context.dimensions.photoPreview,
                  child: Center(
                    child: Icon(
                      context.icons.image,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                errorWidget: Icon(
                  context.icons.image,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
          if ((variant.description ?? '').trim().isNotEmpty) ...[
            spacing.vXs,
            Text(
              variant.description!,
              style:
                  typography.bodyMedium.copyWith(color: colors.textSecondary),
            ),
          ],
          spacing.vMd,
          if (variant.subjects.isEmpty)
            Text(
              l10n.experimentsVariantEmpty,
              style:
                  typography.bodyMedium.copyWith(color: colors.textSecondary),
            )
          else
            for (final subject in variant.subjects)
              _SubjectTile(
                subject: subject,
                observations: variant.observations
                    .where((o) => o.subjectId == subject.id)
                    .toList(),
                onAddObservation: () => onAddObservation(subject),
                onEditObservation: (o) => onEditObservation(subject, o),
                onDeleteObservation: onDeleteObservation,
                onRemoveSubject: () => onRemoveSubject(subject),
              ),
          spacing.vSm,
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddSubjects,
              icon: const Icon(Icons.add),
              label: Text(l10n.experimentsAddSubjects),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final ExperimentSubject subject;
  final List<ExperimentObservation> observations;
  final VoidCallback onAddObservation;
  final Future<void> Function(ExperimentObservation) onEditObservation;
  final Future<void> Function(ExperimentObservation) onDeleteObservation;
  final VoidCallback onRemoveSubject;

  const _SubjectTile({
    required this.subject,
    required this.observations,
    required this.onAddObservation,
    required this.onEditObservation,
    required this.onDeleteObservation,
    required this.onRemoveSubject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final sorted = [...observations]
      ..sort((a, b) => b.observedAt.compareTo(a.observedAt));

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.only(left: spacing.md, bottom: spacing.sm),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Row(
          children: [
              Icon(
                subject.subjectType.isPlant
                    ? context.icons.plantPlaceholder
                    : Icons.eco,
                size: context.dimensions.iconMd,
                color: colors.icon,
              ),
            spacing.hSm,
            Expanded(
              child: Text(
                subject.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.bodyLarge,
              ),
            ),
            Text(
              l10n.experimentsObservationCount(observations.length),
              style: typography.captionSmall.copyWith(color: colors.icon),
            ),
          ],
        ),
        children: [
          if (sorted.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: Text(
                l10n.experimentsNoObservations,
                style:
                    typography.bodySmall.copyWith(color: colors.textSecondary),
              ),
            )
          else
            for (final observation in sorted)
              _ObservationRow(
                observation: observation,
                onEdit: () => onEditObservation(observation),
                onDelete: () => onDeleteObservation(observation),
              ),
          Row(
            children: [
              TextButton.icon(
                onPressed: onAddObservation,
                icon: const Icon(Icons.add),
                label: Text(l10n.experimentsAddObservation),
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: l10n.experimentsDeletedSubject,
                child: IconButton(
                  onPressed: onRemoveSubject,
                  tooltip: l10n.experimentsDeletedSubject,
                  icon: Icon(context.icons.delete, color: colors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ObservationRow extends StatelessWidget {
  final ExperimentObservation observation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ObservationRow({
    required this.observation,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final dateLabel = DateFormat('d MMM y').format(observation.observedAt);
    final metrics = <String>[
      if (observation.heightCm != null)
        '${l10n.experimentsMetricHeight}: ${_number(observation.heightCm!)}',
      if (observation.leafCount != null)
        '${l10n.experimentsMetricLeaves}: ${observation.leafCount}',
      if (observation.moisture != null)
        '${l10n.experimentsMetricMoisture}: ${_number(observation.moisture!)}',
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: typography.captionSmall.copyWith(color: colors.icon),
                ),
                if ((observation.note ?? '').trim().isNotEmpty)
                  Text(observation.note!, style: typography.bodyMedium),
                if (metrics.isNotEmpty)
                  Text(
                    metrics.join('  ·  '),
                    style: typography.bodySmall
                        .copyWith(color: colors.textSecondary),
                  ),
                if ((observation.imageUrl ?? '').isNotEmpty) ...[
                  spacing.vXs,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(context.radii.md),
                    child: Image.network(
                      observation.imageUrl!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        context.icons.image,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(context.icons.edit, color: colors.icon, size: 20),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(context.icons.delete, color: colors.error, size: 20),
          ),
        ],
      ),
    );
  }

  String _number(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
