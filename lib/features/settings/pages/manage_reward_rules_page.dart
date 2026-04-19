import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/reward_rule.dart';
import '../controllers/settings_controller.dart';
import '../widgets/setting_dialogs.dart';

class ManageRewardRulesPage extends StatelessWidget {
  const ManageRewardRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('阶段奖励规则'),
            actions: [
              IconButton(
                tooltip: '新增规则',
                onPressed: controller.isBusy ? null : () => _addRule(context, controller),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: Column(
            children: [
              if (controller.isBusy) const LinearProgressIndicator(),
              Expanded(
                child: controller.rewardRules.isEmpty
                    ? const Center(child: Text('暂无阶段奖励规则'))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.rewardRules.length,
                        onReorder: controller.reorderRewardRules,
                        itemBuilder: (context, index) {
                          final item = controller.rewardRules[index];
                          return Card(
                            key: ValueKey(item.id ?? '${item.periodType.dbValue}-${item.name}'),
                            child: ListTile(
                              leading: const Icon(Icons.drag_indicator),
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.periodType.label} · ${item.thresholdPoints} 分 · ${item.rewardText}'
                                ' · ${item.isEnabled ? '已启用' : '已停用'}',
                              ),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    tooltip: '编辑',
                                    onPressed: () => _editRule(context, controller, item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: '删除',
                                    onPressed: () => _deleteRule(context, controller, item),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addRule(
    BuildContext context,
    SettingsController controller,
  ) async {
    final result = await showDialog<RewardRuleDialogResult>(
      context: context,
      builder: (context) => const RewardRuleDialog(),
    );
    if (result == null) {
      return;
    }
    await controller.addRewardRule(
      name: result.name,
      periodType: result.periodType,
      thresholdPoints: result.thresholdPoints,
      rewardText: result.rewardText,
      isEnabled: result.isEnabled,
    );
  }

  Future<void> _editRule(
    BuildContext context,
    SettingsController controller,
    RewardRule item,
  ) async {
    final result = await showDialog<RewardRuleDialogResult>(
      context: context,
      builder: (context) => RewardRuleDialog(
        initialName: item.name,
        initialPeriodType: item.periodType,
        initialThresholdPoints: item.thresholdPoints,
        initialRewardText: item.rewardText,
        initialEnabled: item.isEnabled,
      ),
    );
    if (result == null) {
      return;
    }
    await controller.updateRewardRule(
      item.copyWith(
        name: result.name,
        periodType: result.periodType,
        thresholdPoints: result.thresholdPoints,
        rewardText: result.rewardText,
        isEnabled: result.isEnabled,
      ),
    );
  }

  Future<void> _deleteRule(
    BuildContext context,
    SettingsController controller,
    RewardRule item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除阶段奖励规则'),
          content: Text('删除“${item.name}”后，将不再参与当前周期奖励进度计算。确定继续吗？'),
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
      await controller.deleteRewardRule(item);
    }
  }
}
