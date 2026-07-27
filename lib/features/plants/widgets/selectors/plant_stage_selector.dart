import 'package:flutter/material.dart';
import '../../../../models/stage_info.dart';

class PlantStageSelector extends StatelessWidget {
  final int selectedStage;
  final ValueChanged<int> onChanged;

  const PlantStageSelector({
    super.key,
    required this.selectedStage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final stage = stageInfos.firstWhere(
      (e) => e.value == selectedStage,
      orElse: () => stageInfos.first,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > 700 ||
            MediaQuery.of(context).orientation == Orientation.landscape;

        if (horizontal) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildSelector(),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: _buildDescription(stage, context),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelector(),
            const SizedBox(height: 16),
            _buildDescription(stage, context),
          ],
        );
      },
    );
  }

  Widget _buildSelector() {
    return RadioGroup<int>(
      groupValue: selectedStage,
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      child: Column(
        children: stageInfos.map((item) {
          return RadioListTile<int>(
            value: item.value,
            title: Text(item.title),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDescription(StageInfo stage, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Описание стадии",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...stage.checklist.map(
          (text) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• "),
                Expanded(child: Text(text)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
