import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_services.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/study_type_utils.dart';
import '../../../data/models/statistics_models.dart';
import '../../../data/models/study_record.dart';
import '../../../shared/widgets/comparison_widgets.dart';
import '../../../shared/widgets/state_views.dart';
import '../../add_record/pages/record_entry_page_runtime.dart';
import '../controllers/records_overview_controller.dart';
import 'record_tag_stats_page.dart';

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

class _RecordsBody extends StatefulWidget {
  const _RecordsBody();

  @override
  State<_RecordsBody> createState() => _RecordsBodyState();
}

class _RecordsBodyState extends State<_RecordsBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<RecordsOverviewController>();
    final isLoading = context
        .select<RecordsOverviewController, bool>((value) => value.isLoading);
    final errorMessage = context.select<RecordsOverviewController, String?>(
        (value) => value.errorMessage);
    final statistics =
        context.select<RecordsOverviewController, StatisticsBundle?>(
            (value) => value.statistics);

    if (isLoading && statistics == null) {
      return const LoadingView(
          message: '\u6b63\u5728\u6c47\u603b\u8bb0\u5f55...');
    }

    if (errorMessage != null && statistics == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorStateCard(
          message: errorMessage,
          onRetry: () => controller.load(),
        ),
      );
    }

    if (statistics == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          _PeriodFilterCard(
            controller: controller,
            statistics: statistics,
            onPickPeriod: () => _pickPeriod(context, controller),
          ),
          const SizedBox(height: 16),
          DualMetricSummaryCard(
            leftTitle: '\u603b\u756a\u8304\u949f\u6570\u91cf',
            leftUnit: '\u4e2a',
            leftSummary: statistics.totalPomodoro,
            rightTitle: '\u603b\u79ef\u5206\u6570\u91cf',
            rightUnit: '\u5206',
            rightSummary: statistics.totalPoints,
          ),
          if (statistics.subPeriodSummaries.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SubPeriodSummarySection(
              granularity: statistics.granularity,
              items: statistics.subPeriodSummaries,
              onTap: (item) async {
                await controller.drillDownTo(item.granularity, item.anchorDate);
                if (!mounted) {
                  return;
                }
                _scrollController.jumpTo(0);
              },
            ),
          ],
          const SizedBox(height: 16),
          _CategorySummarySection(items: statistics.categorySummaries),
          const SizedBox(height: 16),
          Selector<RecordsOverviewController, List<ContentSummary>>(
            selector: (_, value) => value.contentSummaries,
            builder: (context, contentSummaries, child) {
              return _DeferredSection(
                title: '\u5185\u5bb9\u6c47\u603b',
                subtitle: contentSummaries.isEmpty
                    ? '\u5f53\u524d\u5468\u671f\u6682\u65e0\u5185\u5bb9\u6c47\u603b'
                    : '\u5171 ${contentSummaries.length} \u9879\u5185\u5bb9\u3002',
                icon: Icons.menu_book_outlined,
                child: _ContentSummaryList(contentSummaries: contentSummaries),
              );
            },
          ),
          const SizedBox(height: 16),
          Selector<RecordsOverviewController,
              ({List<TagSummary> weaknesses, List<TagSummary> improvements})>(
            selector: (_, value) => (
              weaknesses: value.topWeaknesses,
              improvements: value.topImprovements,
            ),
            builder: (context, tagData, child) {
              final weaknessCount = tagData.weaknesses
                  .fold<int>(0, (sum, item) => sum + item.count);
              final improvementCount = tagData.improvements
                  .fold<int>(0, (sum, item) => sum + item.count);
              return _DeferredSection(
                title: '\u8584\u5f31\u70b9\u4e0e\u6539\u8fdb',
                subtitle:
                    '\u8584\u5f31\u70b9 $weaknessCount \u6b21\uff0c\u6539\u8fdb\u63aa\u65bd $improvementCount \u6b21',
                icon: Icons.fact_check_outlined,
                child: _TagStatsEntrySection(controller: controller),
              );
            },
          ),
          const SizedBox(height: 16),
          _DeferredSection(
            title: '\u8be6\u7ec6\u8bb0\u5f55',
            subtitle:
                '\u5f53\u524d\u5468\u671f ${statistics.details.length} \u6761\u8bb0\u5f55',
            icon: Icons.analytics_outlined,
            child: _DetailListSection(
              records: statistics.details,
              onEdit: (record) async {
                if (record.id == null) {
                  return;
                }
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => RecordEditPage(recordId: record.id!),
                  ),
                );
              },
              onDelete: (record) => _confirmDelete(context, controller, record),
            ),
          ),
          if (errorMessage != null && statistics.details.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
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
          title: const Text('\u5220\u9664\u8bb0\u5f55'),
          content: Text(
              '\u786e\u8ba4\u5220\u9664 ${FormatUtils.formatDateTime(record.occurredAt)} \u8fd9\u6761\u8bb0\u5f55\u5417\uff1f'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('\u53d6\u6d88'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('\u5220\u9664'),
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
        const SnackBar(content: Text('\u8bb0\u5f55\u5df2\u5220\u9664')),
      );
    }
  }
}

class _PeriodFilterCard extends StatelessWidget {
  const _PeriodFilterCard({
    required this.controller,
    required this.statistics,
    required this.onPickPeriod,
  });

  final RecordsOverviewController controller;
  final StatisticsBundle statistics;
  final VoidCallback onPickPeriod;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\u7edf\u8ba1\u8303\u56f4',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _GranularitySelector(
              value: controller.granularity,
              onChanged: controller.setGranularity,
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
                    onPressed: controller.isLoading ? null : onPickPeriod,
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
    );
  }
}

class _CategorySummarySection extends StatelessWidget {
  const _CategorySummarySection({required this.items});

  final List<CategorySummary> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.categoryName,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _CategoryMetricPanel(
                              title: '\u756a\u8304\u949f',
                              valueText: '${item.pomodoro.current} \u4e2a',
                              summary: item.pomodoro,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Container(
                              width: 1,
                              height: 106,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          Expanded(
                            child: _CategoryMetricPanel(
                              title: '\u79ef\u5206',
                              valueText: '${item.points.current} \u5206',
                              summary: item.points,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SubPeriodSummarySection extends StatefulWidget {
  const _SubPeriodSummarySection({
    required this.granularity,
    required this.items,
    required this.onTap,
  });
  final TimeGranularity granularity;
  final List<SubPeriodSummary> items;
  final Future<void> Function(SubPeriodSummary item) onTap;
  @override
  State<_SubPeriodSummarySection> createState() =>
      _SubPeriodSummarySectionState();
}

class _SubPeriodSummarySectionState extends State<_SubPeriodSummarySection> {
  _SubPeriodMetric _metric = _SubPeriodMetric.pomodoro;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _resolveTitle(widget.granularity);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleLarge),
                ),
                _MetricSegmentedSwitch(
                  value: _metric,
                  onChanged: (value) {
                    setState(() {
                      _metric = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SubPeriodBarChart(
              granularity: widget.granularity,
              items: widget.items,
              metric: _metric,
              onTap: widget.onTap,
            ),
          ],
        ),
      ),
    );
  }

  String _resolveTitle(TimeGranularity granularity) {
    switch (granularity) {
      case TimeGranularity.day:
        return '\u5f53\u65e5\u60c5\u51b5';
      case TimeGranularity.week:
        return '\u672c\u5468\u60c5\u51b5';
      case TimeGranularity.month:
        return '\u672c\u6708\u60c5\u51b5';
      case TimeGranularity.year:
        return '\u672c\u5e74\u60c5\u51b5';
    }
  }
}

enum _SubPeriodMetric { pomodoro, points }

class _MetricSegmentedSwitch extends StatelessWidget {
  const _MetricSegmentedSwitch({
    required this.value,
    required this.onChanged,
  });
  final _SubPeriodMetric value;
  final ValueChanged<_SubPeriodMetric> onChanged;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.primary.withValues(alpha: 0.45);
    Widget buildItem(_SubPeriodMetric metric, String label) {
      final selected = value == metric;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(metric),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 156,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          buildItem(_SubPeriodMetric.pomodoro, '\u756a\u8304'),
          buildItem(_SubPeriodMetric.points, '\u79ef\u5206'),
        ],
      ),
    );
  }
}

class _SubPeriodBarChart extends StatelessWidget {
  const _SubPeriodBarChart({
    required this.granularity,
    required this.items,
    required this.metric,
    required this.onTap,
  });
  final TimeGranularity granularity;
  final List<SubPeriodSummary> items;
  final _SubPeriodMetric metric;
  final Future<void> Function(SubPeriodSummary item) onTap;
  @override
  Widget build(BuildContext context) {
    if (granularity == TimeGranularity.day || items.isEmpty) {
      return const SizedBox.shrink();
    }
    final values = items
        .map((item) => metric == _SubPeriodMetric.pomodoro
            ? item.pomodoroCount
            : item.points)
        .toList(growable: false);
    final maxValue = values.fold<int>(0, math.max);
    final chartHeight = switch (granularity) {
      TimeGranularity.week => 238.0,
      TimeGranularity.month => 250.0,
      TimeGranularity.year => 244.0,
      TimeGranularity.day => 0.0,
    };

    if (granularity == TimeGranularity.month) {
      return _MonthCompactBarChart(
        items: items,
        values: values,
        maxValue: maxValue,
        onTap: onTap,
      );
    }

    return SizedBox(
      height: chartHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxBarHeight = constraints.maxHeight -
              (granularity == TimeGranularity.month ? 34 : 54);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(items.length, (index) {
              final item = items[index];
              final value = values[index];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: switch (granularity) {
                      TimeGranularity.week => 5.5,
                      TimeGranularity.month => 1.8,
                      TimeGranularity.year => 4.0,
                      TimeGranularity.day => 0,
                    },
                  ),
                  child: _SubPeriodBar(
                    value: value,
                    maxValue: maxValue,
                    maxBarHeight: maxBarHeight,
                    label: _resolveBottomLabel(item, index),
                    showValueLabel: true,
                    onTap: () => onTap(item),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  String _resolveBottomLabel(SubPeriodSummary item, int index) {
    switch (granularity) {
      case TimeGranularity.week:
        const labels = [
          '\u5468\u4e00',
          '\u5468\u4e8c',
          '\u5468\u4e09',
          '\u5468\u56db',
          '\u5468\u4e94',
          '\u5468\u516d',
          '\u5468\u65e5',
        ];
        return labels[item.anchorDate.weekday - 1];
      case TimeGranularity.month:
        final day = item.anchorDate.day;
        if (day.isOdd) {
          return '$day';
        }
        return '';
      case TimeGranularity.year:
        return '${index + 1}';
      case TimeGranularity.day:
        return '';
    }
  }
}

class _SubPeriodBar extends StatelessWidget {
  const _SubPeriodBar({
    required this.value,
    required this.maxValue,
    required this.maxBarHeight,
    required this.label,
    required this.showValueLabel,
    required this.onTap,
    this.barWidth,
    this.showBottomLabel = true,
  });
  final int value;
  final int maxValue;
  final double maxBarHeight;
  final String label;
  final bool showValueLabel;
  final VoidCallback onTap;
  final double? barWidth;
  final bool showBottomLabel;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const valueLabelHeight = 16.0;
    const valueLabelGap = 6.0;
    final reservedTop =
        showValueLabel ? (valueLabelHeight + valueLabelGap) : 0.0;
    final drawableBarHeight = math.max<double>(0, maxBarHeight - reservedTop);
    final normalized = maxValue == 0 ? 0.0 : value / maxValue;
    final barHeight =
        value <= 0 ? 0.0 : math.max<double>(8, drawableBarHeight * normalized);
    final valueBottom = barHeight + valueLabelGap;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: maxBarHeight,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: barWidth ?? double.infinity,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withValues(alpha: value > 0 ? 0.9 : 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                if (showValueLabel && value > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: valueBottom,
                    child: Text(
                      '$value',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (showBottomLabel) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 18,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthCompactBarChart extends StatelessWidget {
  const _MonthCompactBarChart({
    required this.items,
    required this.values,
    required this.maxValue,
    required this.onTap,
  });

  final List<SubPeriodSummary> items;
  final List<int> values;
  final int maxValue;
  final Future<void> Function(SubPeriodSummary item) onTap;

  @override
  Widget build(BuildContext context) {
    const chartHeight = 220.0;
    const barWidth = 8.0;
    const chartTopPadding = 6.0;
    const xAxisHeight = 24.0;
    final maxBarHeight = chartHeight - xAxisHeight - chartTopPadding;

    return SizedBox(
      height: chartHeight,
      child: Column(
        children: [
          const SizedBox(height: chartTopPadding),
          SizedBox(
            height: maxBarHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(items.length, (index) {
                final item = items[index];
                final value = values[index];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.6),
                    child: _SubPeriodBar(
                      value: value,
                      maxValue: math.max(maxValue, 1),
                      maxBarHeight: maxBarHeight,
                      label: '',
                      showValueLabel: true,
                      showBottomLabel: false,
                      barWidth: barWidth,
                      onTap: () => onTap(item),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            height: xAxisHeight,
            child: _MonthXAxisLabels(items: items),
          ),
        ],
      ),
    );
  }
}

class _MonthXAxisLabels extends StatelessWidget {
  const _MonthXAxisLabels({required this.items});

  final List<SubPeriodSummary> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const labelWidth = 24.0;
    return Row(
      children: List<Widget>.generate(items.length, (index) {
        final day = items[index].anchorDate.day;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.6),
            child: Align(
              alignment: Alignment.topCenter,
              child: OverflowBox(
                minWidth: 0,
                maxWidth: labelWidth,
                alignment: Alignment.topCenter,
                child: Text(
                  day.isOdd ? '$day' : '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 8.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _CategoryMetricPanel extends StatelessWidget {
  const _CategoryMetricPanel({
    required this.title,
    required this.valueText,
    required this.summary,
  });
  final String title;
  final String valueText;
  final MetricSummary summary;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          valueText,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ComparisonLine(label: '\u73af\u6bd4', value: summary.ring),
        const SizedBox(height: 8),
        ComparisonLine(label: '\u540c\u6bd4', value: summary.yoy),
      ],
    );
  }
}

class _ContentSummaryList extends StatelessWidget {
  const _ContentSummaryList({required this.contentSummaries});

  final List<ContentSummary> contentSummaries;

  @override
  Widget build(BuildContext context) {
    if (contentSummaries.isEmpty) {
      return const EmptyStateCard(
        title: '\u6682\u65e0\u5185\u5bb9\u6c47\u603b',
        subtitle:
            '\u5f53\u524d\u5468\u671f\u8fd8\u6ca1\u6709\u5185\u5bb9\u7ef4\u5ea6\u7684\u5b66\u4e60\u8bb0\u5f55\u3002',
        icon: Icons.menu_book_outlined,
      );
    }

    return Column(
      children: contentSummaries
          .map(
            (item) => Card(
              child: ListTile(
                title: Text(item.contentName),
                subtitle: Text(
                    '${item.recordCount} \u6b21\uff0c${item.pomodoroCount} \u4e2a\u756a\u8304\uff0c${item.points} \u5206'),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _TagStatsEntrySection extends StatelessWidget {
  const _TagStatsEntrySection({required this.controller});

  final RecordsOverviewController controller;

  @override
  Widget build(BuildContext context) {
    final weaknessCount =
        controller.topWeaknesses.fold<int>(0, (sum, item) => sum + item.count);
    final improvementCount = controller.topImprovements
        .fold<int>(0, (sum, item) => sum + item.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('\u8584\u5f31\u70b9\u4e0e\u6539\u8fdb',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text(
                '\u67e5\u770b\u8584\u5f31\u70b9\u4e0e\u6539\u8fdb\u8be6\u60c5'),
            subtitle: Text(
                '\u8584\u5f31\u70b9\u5171 $weaknessCount \u6b21\uff0c\u6539\u8fdb\u63aa\u65bd\u5171 $improvementCount \u6b21\u8bb0\u5f55'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: controller,
                    child: const RecordTagStatsPage(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DetailListSection extends StatelessWidget {
  const _DetailListSection({
    required this.records,
    required this.onEdit,
    required this.onDelete,
  });

  final List<StudyRecord> records;
  final ValueChanged<StudyRecord> onEdit;
  final ValueChanged<StudyRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    return _DetailListBody(
      records: records,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}

class _DetailListBody extends StatefulWidget {
  const _DetailListBody({
    required this.records,
    required this.onEdit,
    required this.onDelete,
  });

  final List<StudyRecord> records;
  final ValueChanged<StudyRecord> onEdit;
  final ValueChanged<StudyRecord> onDelete;

  @override
  State<_DetailListBody> createState() => _DetailListBodyState();
}

class _DetailListBodyState extends State<_DetailListBody> {
  static const _pageSize = 10;
  int _visibleCount = _pageSize;

  @override
  void didUpdateWidget(covariant _DetailListBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.records != widget.records) {
      _visibleCount = _pageSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = widget.records;
    final visibleRecords = records.take(_visibleCount).toList(growable: false);
    final remaining = records.length - visibleRecords.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('\u8be6\u7ec6\u8bb0\u5f55',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (records.isEmpty)
          const EmptyStateCard(
            title: '\u5f53\u524d\u5468\u671f\u6682\u65e0\u8bb0\u5f55',
            subtitle:
                '\u5148\u53bb\u201c\u65b0\u589e\u8bb0\u5f55\u201d\u9875\u8bb0\u4e0a\u4e00\u6761\uff0c\u7edf\u8ba1\u4f1a\u81ea\u52a8\u5237\u65b0\u3002',
            icon: Icons.analytics_outlined,
          )
        else ...[
          ...visibleRecords.map(
            (record) => _RecordItemCard(
              record: record,
              onEdit: () => widget.onEdit(record),
              onDelete: () => widget.onDelete(record),
            ),
          ),
          if (remaining > 0) ...[
            const SizedBox(height: 8),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _visibleCount =
                        (_visibleCount + _pageSize).clamp(0, records.length);
                  });
                },
                icon: const Icon(Icons.expand_more),
                label: Text(
                  '\u7ee7\u7eed\u67e5\u770b\u5269\u4f59 $remaining \u6761',
                ),
              ),
            ),
          ],
          if (records.length > _pageSize &&
              _visibleCount >= records.length) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _visibleCount = _pageSize;
                  });
                },
                child: const Text('\u6536\u8d77\u8be6\u7ec6\u8bb0\u5f55'),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _GranularitySelector extends StatelessWidget {
  const _GranularitySelector({
    required this.value,
    required this.onChanged,
  });

  final TimeGranularity value;
  final ValueChanged<TimeGranularity> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = const [
      (TimeGranularity.day, '\u65e5'),
      (TimeGranularity.week, '\u5468'),
      (TimeGranularity.month, '\u6708'),
      (TimeGranularity.year, '\u5e74'),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: options.map((item) {
          final selected = item.$1 == value;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onChanged(item.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selected) ...[
                      Icon(Icons.check,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _DeferredSection extends StatefulWidget {
  const _DeferredSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  State<_DeferredSection> createState() => _DeferredSectionState();
}

class _DeferredSectionState extends State<_DeferredSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(widget.icon),
                title: Text(widget.title),
                subtitle: Text(widget.subtitle),
                trailing:
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                onTap: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
              ),
              if (_expanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: widget.child,
                ),
              ],
            ],
          ),
        ),
      ],
    );
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
    final theme = Theme.of(context);
    final breakLabel = record.breakType == 'long'
        ? '\u957f\u4f11\u606f'
        : '\u77ed\u4f11\u606f';
    final rewardLabel =
        (record.feedbackNameSnapshot ?? record.rewardNameSnapshot).trim();
    final detailLines = _buildDetailLines(record);
    final studyType = StudyTypeUtils.describeForContent(
      categoryName: record.categoryNameSnapshot,
      contentName: record.contentNameSnapshot,
      fallbackPoints: record.points,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    FormatUtils.formatDateTime(record.occurredAt),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: '\u66f4\u591a\u64cd\u4f5c',
                  color: theme.colorScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  menuPadding: const EdgeInsets.symmetric(vertical: 6),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('\u7f16\u8f91'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('\u5220\u9664'),
                    ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Icon(Icons.more_vert),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CompactMetaTag(
                      label:
                          '${record.categoryNameSnapshot} · ${record.contentNameSnapshot}'),
                  _CompactMetaTag(label: studyType.shortLabel),
                  _CompactMetaTag(
                    label: '${record.pomodoroCount} \u4e2a\u756a\u8304',
                  ),
                  _CompactMetaTag(label: '${record.points} \u5206'),
                  _CompactMetaTag(
                    label: rewardLabel.isEmpty
                        ? breakLabel
                        : '$breakLabel · $rewardLabel',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: detailLines
                    .map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          line,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _buildDetailLines(StudyRecord record) {
    final lines = <String>[
      '\u5b66\u4e60\u7c7b\u578b\uff1a${StudyTypeUtils.describeForContent(categoryName: record.categoryNameSnapshot, contentName: record.contentNameSnapshot, fallbackPoints: record.points).label}',
    ];
    if (record.questionCount != null || record.wrongCount != null) {
      lines.add(
          '\u5b8c\u6210\u91cf\uff1a${record.questionCount ?? '-'}\uff0c\u9519\u8bef\u6570 / \u5361\u70b9\u6570\uff1a${record.wrongCount ?? '-'}');
    }
    if (record.detailAmountText != null &&
        record.detailAmountText!.trim().isNotEmpty) {
      lines.add('\u5b8c\u6210\u91cf\uff1a${record.detailAmountText}');
    }
    if (record.weaknessTags.isNotEmpty) {
      lines.add(
        '\u8584\u5f31\u70b9\uff1a${record.weaknessTags.join('\u3001')}',
      );
    }
    if (record.improvementTags.isNotEmpty) {
      lines.add(
        '\u6539\u8fdb\uff1a${record.improvementTags.join('\u3001')}',
      );
    }
    if (record.notes != null && record.notes!.trim().isNotEmpty) {
      lines.add('\u5907\u6ce8\uff1a${record.notes}');
    }
    if (lines.isEmpty) {
      lines.add('\u6682\u65e0\u8be6\u7ec6\u8bb0\u5f55');
    }
    return lines;
  }
}

class _CompactMetaTag extends StatelessWidget {
  const _CompactMetaTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
