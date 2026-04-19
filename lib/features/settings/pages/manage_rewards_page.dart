import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/reward_option.dart';
import '../controllers/settings_controller.dart';
import '../widgets/option_edit_dialog.dart';

class ManageRewardsPage extends StatelessWidget {
  const ManageRewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('奖励管理'),
            actions: [
              IconButton(
                tooltip: '新增奖励',
                onPressed: controller.isBusy ? null : () => _addReward(context, controller),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: Column(
            children: [
              if (controller.isBusy) const LinearProgressIndicator(),
              Expanded(
                child: controller.rewardOptions.isEmpty
                    ? const Center(child: Text('暂无奖励选项'))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.rewardOptions.length,
                        onReorder: controller.reorderRewards,
                        itemBuilder: (context, index) {
                          final item = controller.rewardOptions[index];
                          return _RewardTile(
                            key: ValueKey(item.id ?? item.name),
                            item: item,
                            onEdit: () => _editReward(context, controller, item),
                            onDelete: () => _deleteReward(context, controller, item),
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

  Future<void> _addReward(
    BuildContext context,
    SettingsController controller,
  ) async {
    final result = await showDialog<SimpleOptionDialogResult>(
      context: context,
      builder: (context) => const SimpleOptionDialog(title: '新增奖励', nameLabel: '奖励名称'),
    );
    if (result == null) {
      return;
    }
    await controller.addReward(name: result.name, isEnabled: result.isEnabled);
  }

  Future<void> _editReward(
    BuildContext context,
    SettingsController controller,
    RewardOption item,
  ) async {
    final result = await showDialog<SimpleOptionDialogResult>(
      context: context,
      builder: (context) => SimpleOptionDialog(
        title: '编辑奖励',
        initialName: item.name,
        initialEnabled: item.isEnabled,
        nameLabel: '奖励名称',
      ),
    );
    if (result == null) {
      return;
    }
    await controller.updateReward(
      item.copyWith(name: result.name, isEnabled: result.isEnabled),
    );
  }

  Future<void> _deleteReward(
    BuildContext context,
    SettingsController controller,
    RewardOption item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除奖励'),
        content: Text('删除“${item.name}”后，不会影响历史记录快照。确定继续吗？'),
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
      await controller.deleteReward(item);
    }
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final RewardOption item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      child: ListTile(
        leading: const Icon(Icons.drag_indicator),
        title: Text(item.name),
        subtitle: Text(item.isEnabled ? '已启用' : '已停用'),
        trailing: Wrap(
          spacing: 4,
          children: [
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
      ),
    );
  }
}
