import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/statistics_models.dart';
import '../controllers/records_overview_controller.dart';

class RecordTagStatsPage extends StatelessWidget {
  const RecordTagStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordsOverviewController>(
      builder: (context, controller, child) {
        final statistics = controller.statistics;
        return Scaffold(
          appBar: AppBar(title: const Text('薄弱点与改进措施')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (statistics != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_note_outlined),
                    title: const Text('当前统计周期'),
                    subtitle: Text(statistics.currentPeriod.label),
                  ),
                ),
              const SizedBox(height: 16),
              _TagSection(
                title: '薄弱点 TOP 5',
                emptyText: '当前周期还没有记录薄弱点。',
                items: controller.topWeaknesses,
              ),
              const SizedBox(height: 16),
              _TagSection(
                title: '改进措施 TOP 5',
                emptyText: '当前周期还没有记录改进措施。',
                items: controller.topImprovements,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TagSection extends StatelessWidget {
  const _TagSection({
    required this.title,
    required this.emptyText,
    required this.items,
  });

  final String title;
  final String emptyText;
  final List<TagSummary> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(emptyText),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 10),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.name)),
                        Text('${item.count} 次'),
                      ],
                    ),
                  );
                }).toList(growable: false),
              ),
            ),
          ),
      ],
    );
  }
}
