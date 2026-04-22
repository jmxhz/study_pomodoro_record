import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/category_option.dart';
import '../controllers/settings_controller.dart';
import '../widgets/setting_dialogs.dart';

class ManageCategoriesCleanPage extends StatelessWidget {
  const ManageCategoriesCleanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('分类管理'),
            actions: [
              IconButton(
                tooltip: '新增分类',
                onPressed: controller.isBusy ? null : () => _addCategory(context, controller),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: Column(
            children: [
              if (controller.isBusy) const LinearProgressIndicator(),
              Expanded(
                child: controller.categories.isEmpty
                    ? const Center(child: Text('暂无分类'))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.categories.length,
                        onReorder: controller.reorderCategories,
                        itemBuilder: (context, index) {
                          final item = controller.categories[index];
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
                                        : (value) => controller.updateCategory(
                                            item.copyWith(isEnabled: value),
                                          ),
                                  ),
                                  IconButton(
                                    tooltip: '编辑',
                                    onPressed: () => _editCategory(context, controller, item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: '删除',
                                    onPressed: () => _deleteCategory(context, controller, item),
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

  Future<void> _addCategory(
    BuildContext context,
    SettingsController controller,
  ) async {
    final result = await showDialog<SimpleOptionDialogResult>(
      context: context,
      builder: (context) => const SimpleOptionDialog(
        title: '新增分类',
        nameLabel: '分类名称',
      ),
    );
    if (result == null) {
      return;
    }
    await controller.addCategory(name: result.name, isEnabled: true);
  }

  Future<void> _editCategory(
    BuildContext context,
    SettingsController controller,
    CategoryOption item,
  ) async {
    final result = await showDialog<SimpleOptionDialogResult>(
      context: context,
      builder: (context) => SimpleOptionDialog(
        title: '编辑分类',
        nameLabel: '分类名称',
        initialName: item.name,
        initialEnabled: item.isEnabled,
      ),
    );
    if (result == null) {
      return;
    }
    await controller.updateCategory(
      item.copyWith(name: result.name, isEnabled: item.isEnabled),
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    SettingsController controller,
    CategoryOption item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除分类'),
          content: Text('删除“${item.name}”后，不会影响历史记录中的分类快照。确定继续吗？'),
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
      await controller.deleteCategory(item);
    }
  }
}
