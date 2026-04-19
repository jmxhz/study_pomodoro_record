import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/category_option.dart';
import '../../../data/models/content_option.dart';
import '../controllers/settings_controller.dart';
import '../widgets/setting_dialogs.dart';

class ManageContentsCleanPage extends StatelessWidget {
  const ManageContentsCleanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('内容管理'),
            actions: [
              IconButton(
                tooltip: '新增内容',
                onPressed: controller.isBusy ? null : () => _addContent(context, controller),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: Column(
            children: [
              if (controller.isBusy) const LinearProgressIndicator(),
              Expanded(
                child: controller.contentOptions.isEmpty
                    ? const Center(child: Text('暂无内容'))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.contentOptions.length,
                        onReorder: controller.reorderContents,
                        itemBuilder: (context, index) {
                          final item = controller.contentOptions[index];
                          final categoryName = _categoryNameOf(
                            controller.categories,
                            item.categoryId,
                          );
                          return Card(
                            key: ValueKey(item.id ?? item.name),
                            child: ListTile(
                              leading: const Icon(Icons.drag_indicator),
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.isEnabled ? '已启用' : '已停用'} · 所属：$categoryName'
                                ' · 默认积分 ${item.defaultPoints}'
                                ' · ${item.allowAdjust ? '${item.minPoints}~${item.maxPoints} 可调' : '积分固定'}',
                              ),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    tooltip: '编辑',
                                    onPressed: () => _editContent(context, controller, item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: '删除',
                                    onPressed: () => _deleteContent(context, controller, item),
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

  String _categoryNameOf(List<CategoryOption> categories, int? categoryId) {
    if (categoryId == null) {
      return '全部分类';
    }
    for (final item in categories) {
      if (item.id == categoryId) {
        return item.name;
      }
    }
    return '未找到分类';
  }

  Future<void> _addContent(
    BuildContext context,
    SettingsController controller,
  ) async {
    final result = await showDialog<ContentOptionDialogResult>(
      context: context,
      builder: (context) => ContentOptionDialog(categories: controller.categories),
    );
    if (result == null) {
      return;
    }
    await controller.addContent(
      name: result.name,
      categoryId: result.categoryId,
      isEnabled: result.isEnabled,
      defaultPoints: result.defaultPoints,
      allowAdjust: result.allowAdjust,
      minPoints: result.minPoints,
      maxPoints: result.maxPoints,
    );
  }

  Future<void> _editContent(
    BuildContext context,
    SettingsController controller,
    ContentOption item,
  ) async {
    final result = await showDialog<ContentOptionDialogResult>(
      context: context,
      builder: (context) => ContentOptionDialog(
        categories: controller.categories,
        initialName: item.name,
        initialCategoryId: item.categoryId,
        initialEnabled: item.isEnabled,
        initialDefaultPoints: item.defaultPoints,
        initialAllowAdjust: item.allowAdjust,
        initialMinPoints: item.minPoints,
        initialMaxPoints: item.maxPoints,
      ),
    );
    if (result == null) {
      return;
    }
    await controller.updateContent(
      item.copyWith(
        name: result.name,
        categoryId: result.categoryId,
        clearCategoryId: result.categoryId == null,
        isEnabled: result.isEnabled,
        defaultPoints: result.defaultPoints,
        allowAdjust: result.allowAdjust,
        minPoints: result.minPoints,
        maxPoints: result.maxPoints,
      ),
    );
  }

  Future<void> _deleteContent(
    BuildContext context,
    SettingsController controller,
    ContentOption item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除内容'),
          content: Text('删除“${item.name}”后，不会影响历史记录中的内容快照。确定继续吗？'),
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
      await controller.deleteContent(item);
    }
  }
}
