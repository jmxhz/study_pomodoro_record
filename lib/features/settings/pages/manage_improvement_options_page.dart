import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/improvement_option.dart';
import '../controllers/settings_controller.dart';
import '../widgets/setting_dialogs.dart';

class ManageImprovementOptionsPage extends StatelessWidget {
  const ManageImprovementOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('改进措施管理'),
            actions: [
              IconButton(
                tooltip: '新增改进措施',
                onPressed: controller.isBusy ? null : () => _addItem(context, controller),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: Column(
            children: [
              if (controller.isBusy) const LinearProgressIndicator(),
              Expanded(
                child: controller.improvementOptions.isEmpty
                    ? const Center(child: Text('暂无改进措施选项'))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.improvementOptions.length,
                        onReorder: controller.reorderImprovementOptions,
                        itemBuilder: (context, index) {
                          final item = controller.improvementOptions[index];
                          final categoryName = _categoryNameOf(controller, item.categoryId);
                          return Card(
                            key: ValueKey(item.id ?? item.name),
                            child: ListTile(
                              leading: const Icon(Icons.drag_indicator),
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.isEnabled ? '已启用' : '已停用'} · 绑定：$categoryName',
                              ),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  Switch(
                                    value: item.isEnabled,
                                    onChanged: controller.isBusy
                                        ? null
                                        : (value) => controller.updateImprovementOption(
                                            item.copyWith(isEnabled: value),
                                          ),
                                  ),
                                  IconButton(
                                    tooltip: '编辑',
                                    onPressed: () => _editItem(context, controller, item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: '删除',
                                    onPressed: () => _deleteItem(context, controller, item),
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

  Future<void> _addItem(BuildContext context, SettingsController controller) async {
    final result = await showDialog<ContentOptionDialogResult>(
      context: context,
      builder: (context) => ContentOptionDialog(categories: controller.categories),
    );
    if (result == null) {
      return;
    }
    await controller.addImprovementOption(
      name: result.name,
      categoryId: result.categoryId,
      isEnabled: true,
    );
  }

  Future<void> _editItem(
    BuildContext context,
    SettingsController controller,
    ImprovementOption item,
  ) async {
    final result = await showDialog<ContentOptionDialogResult>(
      context: context,
      builder: (context) => ContentOptionDialog(
        categories: controller.categories,
        initialName: item.name,
        initialCategoryId: item.categoryId,
        initialEnabled: item.isEnabled,
      ),
    );
    if (result == null) {
      return;
    }
    await controller.updateImprovementOption(
      item.copyWith(
        name: result.name,
        categoryId: result.categoryId,
        clearCategoryId: result.categoryId == null,
        isEnabled: item.isEnabled,
      ),
    );
  }

  Future<void> _deleteItem(
    BuildContext context,
    SettingsController controller,
    ImprovementOption item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除改进措施'),
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
      await controller.deleteImprovementOption(item);
    }
  }

  String _categoryNameOf(SettingsController controller, int? categoryId) {
    if (categoryId == null) {
      return '全部分类';
    }
    for (final item in controller.categories) {
      if (item.id == categoryId) {
        return item.name;
      }
    }
    return '未找到分类';
  }
}
