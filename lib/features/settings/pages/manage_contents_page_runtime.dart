import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/study_type_utils.dart';
import '../../../data/models/content_option.dart';
import '../controllers/settings_controller_runtime.dart';
import '../widgets/setting_dialogs_runtime.dart';

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
                onPressed: controller.isBusy
                    ? null
                    : () => _addContent(context, controller),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: Column(
            children: [
              if (controller.isBusy) const LinearProgressIndicator(),
              Expanded(
                child: _ContentList(
                  controller: controller,
                  onEdit: (item) => _editContent(context, controller, item),
                  onDelete: (item) => _deleteContent(context, controller, item),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addContent(
      BuildContext context, SettingsController controller) async {
    final result = await showDialog<ContentOptionDialogResult>(
      context: context,
      builder: (context) =>
          ContentOptionDialog(categories: controller.categories),
    );
    if (result == null) {
      return;
    }
    await controller.addContent(
      name: result.name,
      categoryId: result.categoryId,
      isEnabled: result.isEnabled,
      points: result.points,
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
        initialPoints: item.points,
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
        points: result.points,
        defaultPoints: result.points,
        allowAdjust: false,
        minPoints: result.points,
        maxPoints: result.points,
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
      ),
    );
    if (confirmed == true) {
      await controller.deleteContent(item);
    }
  }
}

class _ContentList extends StatelessWidget {
  const _ContentList({
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final SettingsController controller;
  final ValueChanged<ContentOption> onEdit;
  final ValueChanged<ContentOption> onDelete;

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections(controller);
    if (sections.isEmpty) {
      return const Center(child: Text('暂无内容'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            '已按绑定分类分组显示，组内可拖动调整顺序。',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        if (index == 1) {
          return const SizedBox(height: 12);
        }
        final section = sections[index - 2];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          section.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text('${section.items.length} 项'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: section.items.length,
                    onReorder: (oldIndex, newIndex) {
                      controller.reorderContentsInCategory(
                          section.categoryId, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final item = section.items[index];
                      return Container(
                        key: ValueKey(
                            'content-${section.categoryId ?? 'all'}-${item.id ?? item.name}'),
                        decoration: BoxDecoration(
                          border: Border(
                            top: index == 0
                                ? BorderSide.none
                                : BorderSide(
                                    color: Theme.of(context).dividerColor),
                          ),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.drag_indicator),
                          title: Text(item.name),
                          subtitle: Text(
                            '${item.isEnabled ? '已启用' : '已停用'} · ${StudyTypeUtils.describeForContent(contentName: item.name, categoryName: controller.categoryNameOf(item.categoryId), fallbackPoints: item.points).shortLabel} · 积分 ${item.points}',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: '编辑',
                                onPressed: () => onEdit(item),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: '删除',
                                onPressed: () => onDelete(item),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<_ContentSection> _buildSections(SettingsController controller) {
    final groups = <int?, List<ContentOption>>{};
    for (final item in controller.contentOptions) {
      groups.putIfAbsent(item.categoryId, () => <ContentOption>[]).add(item);
    }

    final knownIds =
        controller.categories.map((item) => item.id).whereType<int>().toSet();
    final orphanIds = groups.keys
        .where((id) => id != null && !knownIds.contains(id))
        .cast<int>()
        .toList(growable: false)
      ..sort();

    final orderedIds = <int?>[
      ...controller.categories.map((item) => item.id),
      ...orphanIds,
      if (groups.containsKey(null)) null,
    ];

    return orderedIds
        .where((categoryId) => groups.containsKey(categoryId))
        .map(
          (categoryId) => _ContentSection(
            categoryId: categoryId,
            title: categoryId == null
                ? '默认'
                : controller.categoryNameOf(categoryId),
            items: groups[categoryId]!,
          ),
        )
        .toList(growable: false);
  }
}

class _ContentSection {
  const _ContentSection({
    required this.categoryId,
    required this.title,
    required this.items,
  });

  final int? categoryId;
  final String title;
  final List<ContentOption> items;
}
