import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/reward_option.dart';
import '../controllers/settings_controller_runtime.dart';
import '../widgets/option_tile_actions.dart';
import '../widgets/setting_dialogs_runtime.dart';

class ManageBreakItemsPage extends StatelessWidget {
  const ManageBreakItemsPage({
    super.key,
    required this.type,
  });

  final String type;

  bool get isLong => type == 'long';

  String get pageTitle => isLong ? '长休息管理' : '短休息管理';

  String get itemLabel => isLong ? '长休息' : '短休息';

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        final items =
            isLong ? controller.longBreakOptions : controller.shortBreakOptions;
        return Scaffold(
          appBar: AppBar(
            title: Text(pageTitle),
            actions: [
              IconButton(
                tooltip: '新增$itemLabel',
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
                child: items.isEmpty
                    ? Center(child: Text('暂无$itemLabel选项'))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        onReorder: (oldIndex, newIndex) {
                          controller.reorderBreaksByType(
                              type, oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            key: ValueKey(
                                '${item.type}-${item.id ?? item.name}'),
                            child: ListTile(
                              isThreeLine: true,
                              leading: const Icon(Icons.drag_indicator),
                              title: Text(item.name),
                              subtitle: Text(item.isEnabled ? '已启用' : '已停用'),
                              trailing: OptionTileActions(
                                isEnabled: item.isEnabled,
                                onEnabledChanged: controller.isBusy
                                    ? null
                                    : (value) => controller.updateReward(
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
    final result = await showDialog<SimpleOptionDialogResult>(
      context: context,
      builder: (context) => SimpleOptionDialog(
        title: '新增$itemLabel',
        nameLabel: '$itemLabel名称',
      ),
    );
    if (result == null) {
      return;
    }
    await controller.addReward(
      name: result.name,
      type: type,
      isEnabled: true,
    );
  }

  Future<void> _editItem(
    BuildContext context,
    SettingsController controller,
    RewardOption item,
  ) async {
    final result = await showDialog<SimpleOptionDialogResult>(
      context: context,
      builder: (context) => SimpleOptionDialog(
        title: '编辑$itemLabel',
        nameLabel: '$itemLabel名称',
        initialName: item.name,
      ),
    );
    if (result == null) {
      return;
    }
    await controller.updateReward(
      item.copyWith(name: result.name, isEnabled: item.isEnabled),
    );
  }

  Future<void> _deleteItem(
    BuildContext context,
    SettingsController controller,
    RewardOption item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除$itemLabel'),
        content: Text('删除“${item.name}”后，不会影响历史记录中的休息快照。确定继续吗？'),
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
