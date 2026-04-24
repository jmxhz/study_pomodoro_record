import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/improvement_option.dart';
import '../controllers/settings_controller_runtime.dart';
import '../widgets/option_tile_actions.dart';
import '../widgets/setting_dialogs_runtime.dart';

class ManageImprovementOptionsHubPage extends StatelessWidget {
  const ManageImprovementOptionsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        final sections = _buildSections(controller);
        return Scaffold(
          appBar: AppBar(title: const Text('改进措施管理')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (controller.isBusy) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
              ],
              Card(
                child: Column(
                  children: sections.map((section) {
                    return Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            section.isLegacy
                                ? Icons.history_toggle_off_outlined
                                : Icons.build_circle_outlined,
                          ),
                          title: Text(section.title),
                          subtitle: Text('当前 ${section.items.length} 项'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: controller,
                                  child:
                                      _ImprovementSectionPage(section: section),
                                ),
                              ),
                            );
                          },
                        ),
                        if (section != sections.last) const Divider(height: 1),
                      ],
                    );
                  }).toList(growable: false),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_ImprovementSection> _buildSections(SettingsController controller) {
    final sections = <_ImprovementSection>[
      for (final content in controller.contentOptions)
        _ImprovementSection(
          title: content.name,
          items: controller.improvementOptions
              .where((item) => item.contentOptionId == content.id)
              .toList(growable: false),
          contentOptionId: content.id,
        ),
    ];

    final legacyGroups = <int?, List<ImprovementOption>>{};
    for (final item in controller.improvementOptions.where(
      (item) => item.contentOptionId == null && item.categoryId != null,
    )) {
      legacyGroups
          .putIfAbsent(item.categoryId, () => <ImprovementOption>[])
          .add(item);
    }

    for (final entry in legacyGroups.entries) {
      sections.add(
        _ImprovementSection(
          title: '旧分类绑定 · ${controller.categoryNameOf(entry.key)}',
          items: entry.value,
          legacyCategoryId: entry.key,
        ),
      );
    }

    return sections;
  }
}

class _ImprovementSectionPage extends StatelessWidget {
  const _ImprovementSectionPage({required this.section});

  final _ImprovementSection section;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        final items = section.isLegacy
            ? controller.improvementOptions
                .where(
                  (item) =>
                      item.contentOptionId == null &&
                      item.categoryId == section.legacyCategoryId,
                )
                .toList(growable: false)
            : controller.improvementOptions
                .where(
                    (item) => item.contentOptionId == section.contentOptionId)
                .toList(growable: false);

        return Scaffold(
          appBar: AppBar(
            title: Text(section.title),
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
                child: items.isEmpty
                    ? const Center(child: Text('当前分组暂无改进措施'))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        onReorder: (oldIndex, newIndex) {
                          if (section.isLegacy) {
                            controller
                                .reorderImprovementOptionsInLegacyCategory(
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
                          final item = items[index];
                          return Card(
                            key: ValueKey(
                                'improvement-${section.title}-${item.id ?? item.name}'),
                            child: ListTile(
                              leading: const Icon(Icons.drag_indicator),
                              title: Text(item.name),
                              subtitle: Text(item.isEnabled ? '已启用' : '已停用'),
                              trailing: OptionTileActions(
                                isEnabled: item.isEnabled,
                                onEnabledChanged: controller.isBusy
                                    ? null
                                    : (value) =>
                                        controller.updateImprovementOption(
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
    final result = await showDialog<ContentBoundOptionDialogResult>(
      context: context,
      builder: (context) => ContentBoundOptionDialog(
        title: '新增改进措施',
        nameLabel: '改进措施名称',
        contentOptions: controller.contentOptions,
        initialContentOptionId: section.contentOptionId,
      ),
    );
    if (result == null) {
      return;
    }
    await controller.addImprovementOption(
      name: result.name,
      contentOptionId: result.contentOptionId,
      isEnabled: true,
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
}

class _ImprovementSection {
  const _ImprovementSection({
    required this.title,
    required this.items,
    this.contentOptionId,
    this.legacyCategoryId,
  });

  final String title;
  final List<ImprovementOption> items;
  final int? contentOptionId;
  final int? legacyCategoryId;

  bool get isLegacy => legacyCategoryId != null;
}
