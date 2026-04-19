import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_services.dart';
import '../../../core/utils/format_utils.dart';
import '../../../data/models/statistics_models.dart';
import '../../../data/models/study_record.dart';
import '../../../shared/widgets/comparison_widgets.dart';
import '../../../shared/widgets/state_views.dart';
import '../../add_record/pages/study_entry_page.dart';
import '../controllers/records_overview_controller.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RecordsOverviewController>(
      create: (context) {
        final services = context.read<AppServices>();
        return RecordsOverviewController(
          optionsRepository: services.optionsRepository,
          studyRecordRepository: services.studyRecordRepository,
          rewardRedemptionRepository: services.rewardRedemptionRepository,
          dataSyncNotifier: services.dataSyncNotifier,
        );
      },
      child: const _RecordsBody(),
    );
  }
}

class _RecordsBody extends StatelessWidget {
  const _RecordsBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordsOverviewController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.statistics == null) {
          return const LoadingView(message: '正在汇总记录...');
        }

        if (controller.errorMessage != null && controller.statistics == null) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ErrorStateCard(
              message: controller.errorMessage!,
              onRetry: () => controller.load(),
            ),
          );
        }

        final statistics = controller.statistics;
        if (statistics == null) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('统计范围',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SegmentedButton<TimeGranularity>(
                        segments: const [
                          ButtonSegment(
                            value: TimeGranularity.day,
                            label: Text('每天'),
                          ),
                          ButtonSegment(
                            value: TimeGranularity.week,
                            label: Text('每周'),
                          ),
                          ButtonSegment(
                            value: TimeGranularity.month,
                            label: Text('每月'),
                          ),
                          ButtonSegment(
                            value: TimeGranularity.year,
                            label: Text('每年'),
                          ),
                        ],
                        selected: {controller.granularity},
                        onSelectionChanged: (selection) {
                          controller.setGranularity(selection.first);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton(
                            onPressed: controller.isLoading
                                ? null
                                : () => controller.shiftPeriod(-1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: controller.isLoading
                                  ? null
                                  : () => _pickPeriod(context, controller),
                              icon: const Icon(Icons.event_outlined),
                              label: Text(statistics.currentPeriod.label),
                            ),
                          ),
                          IconButton(
                            onPressed: controller.isLoading
                                ? null
                                : () => controller.shiftPeriod(1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      if (controller.isLoading) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MetricSummaryCard(
                      title: '总番茄钟数量',
                      unit: '个',
                      summary: statistics.totalPomodoro,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricSummaryCard(
                      title: '总积分数量',
                      unit: '分',
                      summary: statistics.totalPoints,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('分类汇总', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...statistics.categorySummaries.map(
                (item) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.categoryName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text('番茄钟：${item.pomodoro.current} 个'),
                        const SizedBox(height: 6),
                        ComparisonLine(
                            label: '番茄钟环比', value: item.pomodoro.ring),
                        const SizedBox(height: 6),
                        ComparisonLine(
                            label: '番茄钟同比', value: item.pomodoro.yoy),
                        const Divider(height: 24),
                        Text('积分：${item.points.current} 分'),
                        const SizedBox(height: 6),
                        ComparisonLine(label: '积分环比', value: item.points.ring),
                        const SizedBox(height: 6),
                        ComparisonLine(label: '积分同比', value: item.points.yoy),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('明细列表', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (statistics.details.isEmpty)
                const EmptyStateCard(
                  title: '当前周期暂无记录',
                  subtitle: '先去“新增记录”页记上一条，统计会自动刷新。',
                  icon: Icons.analytics_outlined,
                )
              else
                ...statistics.details.map(
                  (record) => _RecordItemCard(
                    record: record,
                    onEdit: () async {
                      if (record.id == null) {
                        return;
                      }
                      await Navigator.of(context).push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) => RecordEditPage(recordId: record.id!),
                        ),
                      );
                    },
                    onDelete: () => _confirmDelete(context, controller, record),
                  ),
                ),
              if (controller.errorMessage != null &&
                  statistics.details.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPeriod(
    BuildContext context,
    RecordsOverviewController controller,
  ) async {
    final result = await showDatePicker(
      context: context,
      initialDate: controller.anchorDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
      initialDatePickerMode: controller.granularity == TimeGranularity.year
          ? DatePickerMode.year
          : DatePickerMode.day,
    );

    if (result == null) {
      return;
    }
    await controller.setAnchorDate(result);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RecordsOverviewController controller,
    StudyRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除记录'),
          content: Text(
            '确认删除 ${FormatUtils.formatDateTime(record.occurredAt)} 的这条记录吗？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await controller.deleteRecord(record);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('记录已删除')),
      );
    }
  }
}

class _RecordItemCard extends StatelessWidget {
  const _RecordItemCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final StudyRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    FormatUtils.formatDateTime(record.occurredAt),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: '编辑',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: '删除',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('分类：${record.categoryNameSnapshot}')),
                Chip(label: Text('内容：${record.contentNameSnapshot}')),
                Chip(label: Text('番茄钟：${record.pomodoroCount}')),
                Chip(label: Text('积分：${record.points}')),
                Chip(label: Text('奖励：${record.rewardNameSnapshot}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
