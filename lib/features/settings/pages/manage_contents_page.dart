import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/content_option.dart';
import '../controllers/settings_controller.dart';
import '../widgets/option_edit_dialog.dart';

class ManageContentsPage extends StatelessWidget {
  const ManageContentsPage({super.key});

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
                    ? const Center(child: Text('暂无内容选项'))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.contentOptions.length,
                        onReorder: controller.reorderContents,
                        itemBuilder: (context, index) {
                          final item = controller.contentOptions[index];
                          return _ContentTile(
                            key: ValueKey(item.id ?? item.name),
                            item: item,
                            categoryName: controller.categoryNameOf(item.categoryId),
                            onEdit: () => _editContent(context, controller, item),
                            onDelete: () => _deleteContent(context, controller, item),
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
      builder: (context) => AlertDialog(
        title: const Text('删除内容'),
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
      await controller.deleteContent(item);
    }
  }
}

class _ContentTile extends StatelessWidget {
  const _ContentTile({
    super.key,
    required this.item,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
  });

  final ContentOption item;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      child: ListTile(
        leading: const Icon(Icons.drag_indicator),
        title: Text(item.name),
        subtitle: Text('${item.isEnabled ? '已启用' : '已停用'} · 绑定：$categoryName'),
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
