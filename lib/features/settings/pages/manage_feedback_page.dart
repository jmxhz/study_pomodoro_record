import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/reward_option.dart';
import '../controllers/settings_controller.dart';
import '../widgets/setting_dialogs.dart';

class ManageFeedbackPage extends StatelessWidget {
  const ManageFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('本轮反馈管理'),
            actions: [
              IconButton(
                tooltip: '新增本轮反馈',
                onPressed: controller.isBusy ? null : () => _addFeedback(context, controller),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: Column(
            children: [
              if (controller.isBusy) const LinearProgressIndicator(),
              Expanded(
                child: controller.rewardOptions.isEmpty
                    ? const Center(child: Text('暂无本轮反馈选项'))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.rewardOptions.length,
                        onReorder: controller.reorderRewards,
                        itemBuilder: (context, index) {
                          final item = controller.rewardOptions[index];
                          return Card(
                            key: ValueKey(item.id ?? item.name),
                            child: ListTile(
                              leading: const Icon(Icons.drag_indicator),
                              title: Text(item.name),
                              subtitle: Text(item.isEnabled ? '已启用' : '已停用'),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  Switch(
                                    value: item.isEnabled,
                                    onChanged: controller.isBusy
                                        ? null
                                        : (value) => controller.updateReward(
                                            item.copyWith(isEnabled: value),
                                          ),
                                  ),
                                  IconButton(
                                    tooltip: '编辑',
                                    onPressed: () => _editFeedback(context, controller, item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: '删除',
                                    onPressed: () => _deleteFeedback(context, controller, item),
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

  Future<void> _addFeedback(
    BuildContext context,
    SettingsController controller,
  ) async {
    final result = await showDialog<SimpleOptionDialogResult>(
      context: context,
      builder: (context) => const SimpleOptionDialog(
        title: '新增本轮反馈',
        nameLabel: '反馈名称',
      ),
    );
    if (result == null) {
      return;
    }
    await controller.addReward(name: result.name, isEnabled: true);
  }

  Future<void> _editFeedback(
    BuildContext context,
    SettingsController controller,
    RewardOption item,
  ) async {
    final result = await showDialog<SimpleOptionDialogResult>(
      context: context,
      builder: (context) => SimpleOptionDialog(
        title: '编辑本轮反馈',
        nameLabel: '反馈名称',
        initialName: item.name,
        initialEnabled: item.isEnabled,
      ),
    );
    if (result == null) {
      return;
    }
    await controller.updateReward(
      item.copyWith(name: result.name, isEnabled: item.isEnabled),
    );
  }

  Future<void> _deleteFeedback(
    BuildContext context,
    SettingsController controller,
    RewardOption item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除本轮反馈'),
          content: Text('删除“${item.name}”后，不会影响历史记录中的反馈快照。确定继续吗？'),
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
      await controller.deleteReward(item);
    }
  }
}
