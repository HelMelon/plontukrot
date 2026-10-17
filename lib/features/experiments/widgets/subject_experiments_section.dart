import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/features/feature_flags.dart';
import '../../../core/theme/theme_context.dart';
import '../../../models/experiment.dart';
import '../../../models/experiment_subject.dart';
import '../../../services/experiment_service.dart';
import '../pages/experiment_details_page.dart';

/// Experiments this plant or propagation batch belongs to. Hidden when the
/// experiments flag is off and when the subject is in none, so the plant page
/// and the propagation sheet stay unchanged for everyone else.
class SubjectExperimentsSection extends StatefulWidget {
  final ExperimentSubjectType subjectType;
  final String subjectId;

  const SubjectExperimentsSection({
    super.key,
    required this.subjectType,
    required this.subjectId,
  });

  @override
  State<SubjectExperimentsSection> createState() =>
      _SubjectExperimentsSectionState();
}

class _SubjectExperimentsSectionState extends State<SubjectExperimentsSection> {
  Stream<List<Experiment>>? _experiments;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FeatureFlagsController.instance,
      builder: (context, _) {
        final enabled = FeatureFlagsController.instance
            .isEnabled(FeatureFlag.experiments);
        if (!enabled) return const SizedBox.shrink();
        _experiments ??= ExperimentService().watchExperiments();
        return StreamBuilder<List<Experiment>>(
          stream: _experiments,
          builder: (context, snapshot) {
            final memberships = membershipsForSubject(
              snapshot.data ?? const [],
              subjectType: widget.subjectType,
              subjectId: widget.subjectId,
            );
            if (memberships.isEmpty) return const SizedBox.shrink();
            return _MembershipSection(memberships: memberships);
          },
        );
      },
    );
  }
}

class _MembershipSection extends StatelessWidget {
  final List<ExperimentSubjectMembership> memberships;

  const _MembershipSection({required this.memberships});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final cards = context.components.cards;
    final typography = context.typography;

    return Padding(
      padding: EdgeInsets.only(top: spacing.md),
      child: Container(
        width: double.infinity,
        padding: cards.padding,
        decoration: cards.decoration.copyWith(color: colors.modal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.experimentsTitle,
              style: typography.sectionTitle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            for (final membership in memberships) ...[
              spacing.vSm,
              _ExperimentLink(membership: membership),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExperimentLink extends StatelessWidget {
  final ExperimentSubjectMembership membership;

  const _ExperimentLink({required this.membership});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final cards = context.components.cards;
    final typography = context.typography;
    final experiment = membership.experiment;
    final title = experiment.title.trim().isEmpty
        ? l10n.experimentsOpen
        : experiment.title.trim();
    final labels = membership.variantLabels;
    final variantLine = labels.isEmpty
        ? null
        : l10n.experimentsParticipantVariant(labels.join(' · '));
    final status = experiment.isCompleted
        ? l10n.experimentsStatusDone
        : l10n.experimentsStatusActive;
    final buttonLabel = [
      title,
      if (variantLine != null) variantLine,
      status,
    ].join('. ');

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(cards.radius),
      child: Semantics(
        button: true,
        label: buttonLabel,
        excludeSemantics: true,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ExperimentDetailsPage(experimentId: experiment.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(cards.radius),
          child: Container(
            width: double.infinity,
            padding: spacing.allMd,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cards.radius),
              border: Border.all(color: colors.outline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: typography.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (variantLine != null) ...[
                        spacing.vXxs,
                        Text(
                          variantLine,
                          style: typography.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      spacing.vXxs,
                      Text(
                        status,
                        style: typography.bodySmall.copyWith(
                          color: colors.icon,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                spacing.hSm,
                ExcludeSemantics(
                  child: Icon(
                    context.icons.chevronRight,
                    color: colors.textSecondary,
                    size: context.dimensions.iconXl,
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
