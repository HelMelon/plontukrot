import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/propagation.dart';
import '../../../models/propagation_year_stats.dart';
import '../../../models/stage_info.dart';
import '../../../services/propagation_service.dart';
import '../../plants/widgets/sheets/propagation_details_sheet.dart';

class PropagationsPage extends StatefulWidget {
  const PropagationsPage({super.key});

  @override
  State<PropagationsPage> createState() => _PropagationsPageState();
}

class _PropagationsPageState extends State<PropagationsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static String _daysLabel(int days) {
    if (days == 0) return 'сегодня';
    if (days == 1) return '1 день';
    if (days >= 2 && days <= 4) return '$days дня';
    return '$days дней';
  }

  static String _stageTitle(int value) {
    return stageInfos
        .firstWhere(
          (stage) => stage.value == value,
          orElse: () => stageInfos[1],
        )
        .title;
  }

  Future<void> _openDetails(
    BuildContext context,
    Propagation propagation,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PropagationDetailsSheet(propagation: propagation),
    );
  }

  Widget _statsCard(PropagationYearStats stats) {
    final methodParts = stats.byMethod.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final familyParts = stats.byFamily.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greenDeep),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Статистика ${stats.year}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Поставлено: ${stats.startedBatches} парт. · ${stats.startedQuantity} шт.',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Продано: ${stats.soldQuantity} шт.',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Погибло: ${stats.lostQuantity} шт.',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          if (methodParts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'По способам: ${methodParts.take(4).map((e) => '${e.key.label} ${e.value}').join(' · ')}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          if (familyParts.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'По семействам: ${familyParts.take(3).map((e) => '${e.key} ${e.value}').join(' · ')}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.greenDeep),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.accentLight),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.warmGray,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _propagationTile(Propagation item, {required bool archived}) {
    final subtitle = archived
        ? '${item.status.label} · ${item.quantity} ${item.method.pluralLabel}'
        : '${item.quantityAlive} ${item.method.pluralLabel} · ${DateFormat('d MMM y').format(item.startedAt)}';

    final title = archived
        ? '${_stageTitle(item.stage)} · ${item.status.label}'
        : '${_stageTitle(item.stage)} · ${_daysLabel(item.daysSinceStart)}';

    return InkWell(
      onTap: () => _openDetails(context, item),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.greenDeep),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.parentPlantName,
                    style: const TextStyle(
                      color: AppColors.heading,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if (archived &&
                      (item.soldQuantity > 0 || item.lostQuantity > 0)) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (item.soldQuantity > 0) 'продано ${item.soldQuantity}',
                        if (item.lostQuantity > 0) 'погибло ${item.lostQuantity}',
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppColors.accentLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = PropagationService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Размножение',
          style: TextStyle(
            color: AppColors.heading,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldAccent,
          labelColor: AppColors.goldAccent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Активные'),
            Tab(text: 'Архив'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: StreamBuilder<PropagationYearStats>(
              stream: service.watchYearStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(height: 8);
                }
                return _statsCard(snapshot.data!);
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StreamBuilder<List<Propagation>>(
                  stream: service.watchActivePropagations(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Ошибка: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.goldAccent,
                        ),
                      );
                    }

                    final items = snapshot.data ?? const <Propagation>[];
                    if (items.isEmpty) {
                      return _emptyState(
                        icon: Icons.spa_outlined,
                        title: 'Нет активных размножений',
                        subtitle: 'Добавьте партию со страницы растения',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _propagationTile(items[index], archived: false);
                      },
                    );
                  },
                ),
                StreamBuilder<List<Propagation>>(
                  stream: service.watchArchivedPropagations(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.goldAccent,
                        ),
                      );
                    }

                    final items = snapshot.data ?? const <Propagation>[];
                    if (items.isEmpty) {
                      return _emptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Архив пуст',
                        subtitle: 'Проданные и погибшие партии хранятся 1 год',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _propagationTile(items[index], archived: true);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
