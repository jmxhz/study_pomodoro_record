import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/redeem_reward.dart';
import '../controllers/settings_controller_runtime.dart';
import '../widgets/option_tile_actions.dart';
import '../widgets/setting_dialogs_runtime.dart';

class ManageRedeemRewardsPage extends StatelessWidget {
  const ManageRedeemRewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('奖励兑换管理'),
            actions: [
              IconButton(
                tooltip: '新增奖励兑换项',
                onPressed: controller.isBusy
                    ? null
                    : () => _addItem(context, controller),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: Column(
            children: [
              if (controller.isBusy) const LinearProgressIndicator(),
              Expanded(
                child: controller.redeemRewards.isEmpty
                    ? const Center(child: Text('暂无奖励兑换项'))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.redeemRewards.length,
                        onReorder: controller.reorderRedeemRewards,
                        itemBuilder: (context, index) {
                          final item = controller.redeemRewards[index];
                          final noteText =
                              item.note == null || item.note!.isEmpty
                                  ? ''
                                  : ' · ${item.note}';
                          return Card(
                            key: ValueKey(item.id ?? item.name),
                            child: ListTile(
                              leading: const Icon(Icons.drag_indicator),
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.costPoints} 分 · ${item.isEnabled ? '已启用' : '已停用'}$noteText',
                              ),
                              trailing: OptionTileActions(
                                isEnabled: item.isEnabled,
                                onEnabledChanged: controller.isBusy
                                    ? null
                                    : (value) => controller.updateRedeemReward(
                                          item.copyWith(isEnabled: value),
                                        ),
                                onEdit: () =>
                                    _editItem(context, controller, item),
                                onDelete: () =>
                                    _deleteItem(context, controller, item),
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

  Future<void> _addItem(
      BuildContext context, SettingsController controller) async {
    final result = await showDialog<RedeemRewardDialogResult>(
      context: context,
      builder: (context) => const RedeemRewardDialog(),
    );
    if (result == null) {
      return;
    }
    await controller.addRedeemReward(
      name: result.name,
      costPoints: result.costPoints,
      note: result.note,
      isEnabled: true,
    );
  }

  Future<void> _editItem(
    BuildContext context,
    SettingsController controller,
    RedeemReward item,
  ) async {
    final result = await showDialog<RedeemRewardDialogResult>(
      context: context,
      builder: (context) => RedeemRewardDialog(
        initialName: item.name,
        initialCostPoints: item.costPoints,
        initialNote: item.note,
      ),
    );
    if (result == null) {
      return;
    }
    await controller.updateRedeemReward(
      item.copyWith(
        name: result.name,
        costPoints: result.costPoints,
        note: result.note,
        clearNote: result.note == null,
        isEnabled: item.isEnabled,
      ),
    );
  }

  Future<void> _deleteItem(
    BuildContext context,
    SettingsController controller,
    RedeemReward item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除奖励兑换项'),
        content: Text('确定删除“${item.name}”吗？'),
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
      ),
    );
    if (confirmed == true) {
      await controller.deleteRedeemReward(item);
    }
  }
}
