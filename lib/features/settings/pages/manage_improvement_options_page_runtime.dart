import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/improvement_option.dart';
import '../controllers/settings_controller_runtime.dart';
import '../widgets/setting_dialogs_runtime.dart';

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
                child: _ImprovementList(
                  controller: controller,
                  onEdit: (item) => _editItem(context, controller, item),
                  onDelete: (item) => _deleteItem(context, controller, item),
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
    final result = await showDialog<ContentBoundOptionDialogResult>(
      context: context,
      builder: (context) => ContentBoundOptionDialog(
        title: '新增改进措施',
        nameLabel: '改进措施名称',
        contentOptions: controller.contentOptions,
      ),
    );
    if (result == null) {
      return;
    }
    await controller.addImprovementOption(
      name: result.name,
      contentOptionId: result.contentOptionId,
      isEnabled: result.isEnabled,
    );
  }

  Future<void> _editItem(
    BuildContext context,
    SettingsController controller,
    ImprovementOption item,
  ) async {
    final result = await showDialog<ContentBoundOptionDialogResult>(
      context: context,
      builder: (context) => ContentBoundOptionDialog(
        title: '编辑改进措施',
        nameLabel: '改进措施名称',
        contentOptions: controller.contentOptions,
        initialName: item.name,
        initialContentOptionId: item.contentOptionId,
        initialEnabled: item.isEnabled,
      ),
    );
    if (result == null) {
      return;
    }
    await controller.updateImprovementOption(
      item.copyWith(
        name: result.name,
        categoryId: result.contentOptionId == null ? item.categoryId : null,
        clearCategoryId: result.contentOptionId != null,
        contentOptionId: result.contentOptionId,
        clearContentOptionId: result.contentOptionId == null,
        isEnabled: result.isEnabled,
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
}

class _ImprovementList extends StatelessWidget {
  const _ImprovementList({
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final SettingsController controller;
  final ValueChanged<ImprovementOption> onEdit;
  final ValueChanged<ImprovementOption> onDelete;

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections(controller);
    if (sections.isEmpty) {
      return const Center(child: Text('暂无改进措施选项'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            '已按绑定内容分组显示，旧分类绑定会单独归档显示，组内可拖动调整顺序。',
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
                      if (section.legacyCategoryId != null) {
                        controller.reorderImprovementOptionsInLegacyCategory(
                          section.legacyCategoryId,
                          oldIndex,
                          newIndex,
                        );
                      } else {
                        controller.reorderImprovementOptionsInCategory(
                          section.contentOptionId,
                          oldIndex,
                          newIndex,
                        );
                      }
                    },
                    itemBuilder: (context, index) {
                      final item = section.items[index];
                      return Container(
                        key: ValueKey(
                          'improvement-${section.groupKey}-${item.id ?? item.name}',
                        ),
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
                          subtitle: Text(item.isEnabled ? '已启用' : '已停用'),
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

  List<_ImprovementSection> _buildSections(SettingsController controller) {
    final contentGroups = <int?, List<ImprovementOption>>{};
    final legacyCategoryGroups = <int?, List<ImprovementOption>>{};
    for (final item in controller.improvementOptions) {
      if (item.contentOptionId != null || item.categoryId == null) {
        contentGroups
            .putIfAbsent(item.contentOptionId, () => <ImprovementOption>[])
            .add(item);
      } else {
        legacyCategoryGroups
            .putIfAbsent(item.categoryId, () => <ImprovementOption>[])
            .add(item);
      }
    }

    final knownContentIds = controller.contentOptions
        .map((item) => item.id)
        .whereType<int>()
        .toSet();
    final orphanContentIds = contentGroups.keys
        .where((id) => id != null && !knownContentIds.contains(id))
        .cast<int>()
        .toList(growable: false)
      ..sort();

    final sections = <_ImprovementSection>[
      ...[
        ...controller.contentOptions.map((item) => item.id),
        ...orphanContentIds,
        if (contentGroups.containsKey(null)) null,
      ]
          .where(
              (contentOptionId) => contentGroups.containsKey(contentOptionId))
          .map(
            (contentOptionId) => _ImprovementSection(
              groupKey: 'content-${contentOptionId ?? 'none'}',
              contentOptionId: contentOptionId,
              legacyCategoryId: null,
              title: contentOptionId == null
                  ? '未绑定内容'
                  : controller.contentNameOf(contentOptionId),
              items: contentGroups[contentOptionId]!,
            ),
          ),
    ];

    final knownCategoryIds =
        controller.categories.map((item) => item.id).whereType<int>().toSet();
    final orphanCategoryIds = legacyCategoryGroups.keys
        .where((id) => id != null && !knownCategoryIds.contains(id))
        .cast<int>()
        .toList(growable: false)
      ..sort();

    sections.addAll(
      [
        ...controller.categories.map((item) => item.id),
        ...orphanCategoryIds,
      ].where((categoryId) => legacyCategoryGroups.containsKey(categoryId)).map(
            (categoryId) => _ImprovementSection(
              groupKey: 'legacy-$categoryId',
              contentOptionId: null,
              legacyCategoryId: categoryId,
              title: '旧分类绑定 · ${controller.categoryNameOf(categoryId)}',
              items: legacyCategoryGroups[categoryId]!,
            ),
          ),
    );

    return sections;
  }
}

class _ImprovementSection {
  const _ImprovementSection({
    required this.groupKey,
    required this.contentOptionId,
    required this.legacyCategoryId,
    required this.title,
    required this.items,
  });

  final String groupKey;
  final int? contentOptionId;
  final int? legacyCategoryId;
  final String title;
  final List<ImprovementOption> items;
}
