import 'package:flutter/material.dart';

import '../../data/models/statistics_models.dart';

class ComparisonLine extends StatelessWidget {
  const ComparisonLine({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final ComparisonValue value;

  @override
  Widget build(BuildContext context) {
    final (icon, color, deltaPrefix) = switch (value.direction) {
      TrendDirection.up => (Icons.arrow_upward, Colors.green, '+'),
      TrendDirection.down => (Icons.arrow_downward, Colors.red, ''),
      TrendDirection.flat => (Icons.remove, Colors.grey, ''),
    };
    final deltaText = value.direction == TrendDirection.flat
        ? '0'
        : '$deltaPrefix${value.delta}';
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final trendStyle = theme.textTheme.bodyMedium?.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );
    final percentStyle = theme.textTheme.bodyMedium?.copyWith(
      color: color,
      height: 1.15,
      fontSize: 12.5,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label：', style: labelStyle),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 3),
                    Text(
                      deltaText,
                      style: trendStyle,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      value.percentText,
                      style: percentStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DualMetricSummaryCard extends StatelessWidget {
  const DualMetricSummaryCard({
    super.key,
    required this.leftTitle,
    required this.leftUnit,
    required this.leftSummary,
    required this.rightTitle,
    required this.rightUnit,
    required this.rightSummary,
  });

  final String leftTitle;
  final String leftUnit;
  final MetricSummary leftSummary;
  final String rightTitle;
  final String rightUnit;
  final MetricSummary rightSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MetricSummaryColumn(
                title: leftTitle,
                unit: leftUnit,
                summary: leftSummary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                width: 1,
                height: 118,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            Expanded(
              child: _MetricSummaryColumn(
                title: rightTitle,
                unit: rightUnit,
                summary: rightSummary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricSummaryColumn extends StatelessWidget {
  const _MetricSummaryColumn({
    required this.title,
    required this.unit,
    required this.summary,
  });

  final String title;
  final String unit;
  final MetricSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${summary.current} $unit',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ComparisonLine(label: '环比', value: summary.ring),
        const SizedBox(height: 8),
        ComparisonLine(label: '同比', value: summary.yoy),
      ],
    );
  }
}
