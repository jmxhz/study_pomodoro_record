import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_services.dart';
import '../../../core/utils/format_utils.dart';
import '../../../data/models/redeem_reward.dart';
import '../../../data/models/reward_redemption_record.dart';
import '../../../data/repositories/reward_redemption_repository.dart';
import '../../../shared/widgets/state_views.dart';
import '../controllers/rewards_center_controller.dart';

class RewardsCenterPage extends StatelessWidget {
  const RewardsCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RewardsCenterController>(
      create: (context) {
        final services = context.read<AppServices>();
        return RewardsCenterController(
          optionsRepository: services.optionsRepository,
          studyRecordRepository: services.studyRecordRepository,
          rewardRedemptionRepository: services.rewardRedemptionRepository,
          dataSyncNotifier: services.dataSyncNotifier,
        );
      },
      child: const _RewardsCenterBody(),
    );
  }
}

class _RewardsCenterBody extends StatelessWidget {
  const _RewardsCenterBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<RewardsCenterController>();
    final isLoading = context.select<RewardsCenterController, bool>((value) => value.isLoading);
    final errorMessage =
        context.select<RewardsCenterController, String?>((value) => value.errorMessage);
    final rewardsCount =
        context.select<RewardsCenterController, int>((value) => value.redeemRewards.length);
    final currentWeekCount = context.select<RewardsCenterController, int>(
      (value) => value.currentWeekRedemptionRecords.length,
    );
    final isBusy = context.select<RewardsCenterController, bool>((value) => value.isBusy);

    if (isLoading && rewardsCount == 0 && currentWeekCount == 0) {
      return const LoadingView(message: '正在加载积分奖励...');
    }

    if (errorMessage != null && rewardsCount == 0 && currentWeekCount == 0) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorStateCard(
          message: errorMessage,
          onRetry: () => controller.load(),
        ),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isBusy) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
          ],
          const _PointsLedgerSection(),
          const SizedBox(height: 16),
          _RewardsPoolSection(
            onRedeem: (reward) => _confirmRedeem(context, controller, reward),
          ),
          const SizedBox(height: 16),
          _RedemptionHistorySection(
            onUndo: (record) => _confirmUndo(context, controller, record),
          ),
          if (errorMessage != null && (currentWeekCount > 0 || rewardsCount > 0)) ...[
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

  Future<void> _confirmRedeem(
    BuildContext context,
    RewardsCenterController controller,
    RedeemReward reward,
  ) async {
    final noteController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('确认兑换'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('确定兑换“${reward.name}”吗？将消耗 ${reward.costPoints} 分。'),
                if (reward.note != null && reward.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('奖励备注：${reward.note!}'),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '兑换备注（可选）',
                    hintText: '例如：今天状态不错，奖励自己一下',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('兑换'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      await controller.redeemReward(
        reward,
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已兑换：${reward.name}')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      noteController.dispose();
    }
  }

  Future<void> _confirmUndo(
    BuildContext context,
    RewardsCenterController controller,
    RewardRedemptionRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('撤销兑换'),
          content: Text('确认撤销“${record.rewardNameSnapshot}”这次兑换吗？将返还 ${record.costPoints} 分。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('撤销'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await controller.undoRedemption(record);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已撤销：${record.rewardNameSnapshot}')),
    );
  }
}

class _PointsLedgerSection extends StatelessWidget {
  const _PointsLedgerSection();

  @override
  Widget build(BuildContext context) {
    final totalEarnedPoints =
        context.select<RewardsCenterController, int>((value) => value.totalEarnedPoints);
    final totalRedeemedPoints =
        context.select<RewardsCenterController, int>((value) => value.totalRedeemedPoints);
    final availablePoints =
        context.select<RewardsCenterController, int>((value) => value.availablePoints);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('积分结算', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: '累计获得积分',
                value: '$totalEarnedPoints',
                unit: '分',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: '已兑换积分',
                value: '$totalRedeemedPoints',
                unit: '分',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: '当前可用积分',
                value: '$availablePoints',
                unit: '分',
                emphasize: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RewardsPoolSection extends StatelessWidget {
  const _RewardsPoolSection({
    required this.onRedeem,
  });

  final ValueChanged<RedeemReward> onRedeem;

  @override
  Widget build(BuildContext context) {
    final availablePoints =
        context.select<RewardsCenterController, int>((value) => value.availablePoints);
    final rewards =
        context.select<RewardsCenterController, List<RedeemReward>>((value) => value.redeemRewards);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('奖励中心', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (rewards.isEmpty)
          const EmptyStateCard(
            title: '暂无可兑换奖励',
            subtitle: '可以先去设置页补充奖励兑换项。',
            icon: Icons.redeem_outlined,
          )
        else
          ...rewards.map((reward) {
            final canRedeem = availablePoints >= reward.costPoints;
            final noteText = reward.note == null || reward.note!.trim().isEmpty ? '' : ' · ${reward.note!}';
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(reward.name),
                subtitle: Text('${reward.costPoints} 分$noteText'),
                trailing: FilledButton(
                  onPressed: canRedeem ? () => onRedeem(reward) : null,
                  child: Text(canRedeem ? '兑换' : '积分不足'),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _RedemptionHistorySection extends StatelessWidget {
  const _RedemptionHistorySection({
    required this.onUndo,
  });

  final ValueChanged<RewardRedemptionRecord> onUndo;

  @override
  Widget build(BuildContext context) {
    final records = context.select<RewardsCenterController, List<RewardRedemptionRecord>>(
      (value) => value.currentWeekRedemptionRecords,
    );
    final historyCount =
        context.select<RewardsCenterController, int>((value) => value.historyRedemptionCount);
    final rewardRedemptionRepository = context.select<RewardsCenterController, RewardRedemptionRepository>(
      (value) => value.rewardRedemptionRepository,
    );
    final currentWeekStart = _startOfWeek(DateTime.now());
    final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('本周兑换记录', style: Theme.of(context).textTheme.titleLarge),
            ),
            if (historyCount > 0)
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _RedemptionHistoryPage(
                        rewardRedemptionRepository: rewardRedemptionRepository,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.history_outlined),
                label: Text('历史记录（$historyCount）'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (records.isEmpty)
          EmptyStateCard(
            title: '本周暂无兑换记录',
            subtitle: historyCount == 0 ? '兑换奖励后，这里会展示本周记录。' : '本周还没有兑换记录，历史记录可在右上角查看。',
            icon: Icons.history_outlined,
          )
        else
          _WeeklyRedemptionGroupCard(
            label: _weekLabel(currentWeekStart, currentWeekEnd),
            records: records,
            allowUndo: true,
            onUndo: onUndo,
          ),
      ],
    );
  }
}

class _RedemptionHistoryPage extends StatefulWidget {
  const _RedemptionHistoryPage({
    required this.rewardRedemptionRepository,
  });

  final RewardRedemptionRepository rewardRedemptionRepository;

  @override
  State<_RedemptionHistoryPage> createState() => _RedemptionHistoryPageState();
}

class _RedemptionHistoryPageState extends State<_RedemptionHistoryPage> {
  static const _pageSize = 8;
  late Future<List<_WeeklyRedemptionGroup>> _future;
  int _visibleGroupCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _future = _loadHistory();
  }

  Future<List<_WeeklyRedemptionGroup>> _loadHistory() async {
    final currentWeekStart = _startOfWeek(DateTime.now());
    final records = await widget.rewardRedemptionRepository.getRecordsBefore(currentWeekStart);
    return _groupByWeek(records);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('兑换历史记录')),
      body: FutureBuilder<List<_WeeklyRedemptionGroup>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingView(message: '正在加载历史记录...');
          }
          final weeklyGroups = snapshot.data!;
          final visibleGroups = weeklyGroups.take(_visibleGroupCount).toList(growable: false);
          final remainingCount = weeklyGroups.length - visibleGroups.length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (weeklyGroups.isEmpty)
                const EmptyStateCard(
                  title: '暂无历史记录',
                  subtitle: '当前还没有本周以前的兑换记录。',
                  icon: Icons.history_outlined,
                )
              else
                ...visibleGroups.map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WeeklyRedemptionGroupCard(
                      label: _weekLabel(group.start, group.end),
                      records: group.records,
                    ),
                  ),
                ),
              if (remainingCount > 0) ...[
                const SizedBox(height: 8),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _visibleGroupCount =
                            (_visibleGroupCount + _pageSize).clamp(0, weeklyGroups.length);
                      });
                    },
                    icon: const Icon(Icons.expand_more),
                    label: Text('继续查看剩余 $remainingCount 周'),
                  ),
                ),
              ],
              if (weeklyGroups.length > _pageSize && _visibleGroupCount >= weeklyGroups.length) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _visibleGroupCount = _pageSize;
                      });
                    },
                    child: const Text('收起历史记录'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _WeeklyRedemptionGroupCard extends StatelessWidget {
  const _WeeklyRedemptionGroupCard({
    required this.label,
    required this.records,
    this.allowUndo = false,
    this.onUndo,
  });

  final String label;
  final List<RewardRedemptionRecord> records;
  final bool allowUndo;
  final ValueChanged<RewardRedemptionRecord>? onUndo;

  @override
  Widget build(BuildContext context) {
    final totalPoints = records.fold<int>(0, (sum, item) => sum + item.costPoints);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${records.length} 次 · $totalPoints 分',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ...records.map(
          (item) => Card(
            child: ListTile(
              title: Text(item.rewardNameSnapshot),
              subtitle: Text(_subtitle(item)),
              trailing: allowUndo
                  ? TextButton.icon(
                      onPressed: item.id == null ? null : () => onUndo?.call(item),
                      icon: const Icon(Icons.undo_outlined),
                      label: const Text('撤销'),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

List<_WeeklyRedemptionGroup> _groupByWeek(List<RewardRedemptionRecord> source) {
  final records = [...source]..sort((a, b) => b.redeemedAt.compareTo(a.redeemedAt));
  final groups = <_WeeklyRedemptionGroup>[];

  for (final item in records) {
    final start = _startOfWeek(item.redeemedAt);
    final end = start.add(const Duration(days: 6));
    if (groups.isNotEmpty &&
        _isSameDay(groups.last.start, start) &&
        _isSameDay(groups.last.end, end)) {
      groups.last.records.add(item);
      continue;
    }
    groups.add(
      _WeeklyRedemptionGroup(
        start: start,
        end: end,
        records: [item],
      ),
    );
  }

  return groups;
}

DateTime _startOfWeek(DateTime value) {
  final date = DateTime(value.year, value.month, value.day);
  return date.subtract(Duration(days: value.weekday - DateTime.monday));
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _weekLabel(DateTime start, DateTime end) {
  final startLabel = '${start.year}年${start.month}月${start.day}日';
  final endLabel = start.year == end.year
      ? (start.month == end.month ? '${end.day}日' : '${end.month}月${end.day}日')
      : '${end.year}年${end.month}月${end.day}日';
  return '$startLabel - $endLabel';
}

String _subtitle(RewardRedemptionRecord item) {
  final note = item.note == null || item.note!.trim().isEmpty ? '' : ' · ${item.note!}';
  return '${FormatUtils.formatDateTime(item.redeemedAt)} · ${item.costPoints} 分$note';
}

class _WeeklyRedemptionGroup {
  _WeeklyRedemptionGroup({
    required this.start,
    required this.end,
    required this.records,
  });

  final DateTime start;
  final DateTime end;
  final List<RewardRedemptionRecord> records;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final String unit;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final color = emphasize ? Theme.of(context).colorScheme.primary : null;
    return SizedBox(
      height: 112,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(unit, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
