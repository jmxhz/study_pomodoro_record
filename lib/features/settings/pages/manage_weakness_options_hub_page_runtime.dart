import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/weakness_option.dart';
import '../controllers/settings_controller_runtime.dart';
import '../widgets/setting_dialogs_runtime.dart';

class ManageWeaknessOptionsHubPage extends StatelessWidget {
  const ManageWeaknessOptionsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        final sections = _buildSections(controller);
        return Scaffold(
          appBar: AppBar(title: const Text('薄弱点管理')),
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
                                : Icons.label_outline,
                          ),
                          title: Text(section.title),
                          subtitle: Text('当前 ${section.items.length} 项'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: controller,
                                  child: _WeaknessSectionPage(section: section),
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

  List<_WeaknessSection> _buildSections(SettingsController controller) {
    final sections = <_WeaknessSection>[
      for (final content in controller.contentOptions)
        _WeaknessSection(
          title: content.name,
          items: controller.weaknessOptions
              .where((item) => item.contentOptionId == content.id)
              .toList(growable: false),
          contentOptionId: content.id,
        ),
    ];

    final legacyGroups = <int?, List<WeaknessOption>>{};
    for (final item in controller.weaknessOptions.where(
      (item) => item.contentOptionId == null && item.categoryId != null,
    )) {
      legacyGroups
          .putIfAbsent(item.categoryId, () => <WeaknessOption>[])
          .add(item);
    }

    for (final entry in legacyGroups.entries) {
      sections.add(
        _WeaknessSection(
          title: '旧分类绑定 · ${controller.categoryNameOf(entry.key)}',
          items: entry.value,
          legacyCategoryId: entry.key,
        ),
      );
    }

    return sections;
  }
}

class _WeaknessSectionPage extends StatelessWidget {
  const _WeaknessSectionPage({required this.section});

  final _WeaknessSection section;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        final items = section.isLegacy
            ? controller.weaknessOptions
                .where(
                  (item) =>
                      item.contentOptionId == null &&
                      item.categoryId == section.legacyCategoryId,
                )
                .toList(growable: false)
            : controller.weaknessOptions
                .where(
                    (item) => item.contentOptionId == section.contentOptionId)
                .toList(growable: false);

        return Scaffold(
          appBar: AppBar(
            title: Text(section.title),
            actions: [
              IconButton(
                tooltip: '新增薄弱点',
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
                    ? const Center(child: Text('当前分组暂无薄弱点'))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        onReorder: (oldIndex, newIndex) {
                          if (section.isLegacy) {
                            controller.reorderWeaknessOptionsInLegacyCategory(
                              section.legacyCategoryId,
                              oldIndex,
                              newIndex,
                            );
                          } else {
                            controller.reorderWeaknessOptionsInCategory(
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
                                'weakness-${section.title}-${item.id ?? item.name}'),
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
                                        : (value) =>
                                            controller.updateWeaknessOption(
                                              item.copyWith(isEnabled: value),
                                            ),
                                  ),
                                  IconButton(
                                    tooltip: '编辑',
                                    onPressed: () =>
                                        _editItem(context, controller, item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: '删除',
                                    onPressed: () =>
                                        _deleteItem(context, controller, item),
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

  Future<void> _addItem(
      BuildContext context, SettingsController controller) async {
    final result = await showDialog<ContentBoundOptionDialogResult>(
      context: context,
      builder: (context) => ContentBoundOptionDialog(
        title: '新增薄弱点',
        nameLabel: '薄弱点名称',
        contentOptions: controller.contentOptions,
        initialContentOptionId: section.contentOptionId,
      ),
    );
    if (result == null) {
      return;
    }
    await controller.addWeaknessOption(
      name: result.name,
      contentOptionId: result.contentOptionId,
      isEnabled: true,
    );
  }

  Future<void> _editItem(
    BuildContext context,
    SettingsController controller,
    WeaknessOption item,
  ) async {
    final result = await showDialog<ContentBoundOptionDialogResult>(
      context: context,
      builder: (context) => ContentBoundOptionDialog(
        title: '编辑薄弱点',
        nameLabel: '薄弱点名称',
        contentOptions: controller.contentOptions,
        initialName: item.name,
        initialContentOptionId: item.contentOptionId,
      ),
    );
    if (result == null) {
      return;
    }
    await controller.updateWeaknessOption(
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
    WeaknessOption item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除薄弱点'),
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
      await controller.deleteWeaknessOption(item);
    }
  }
}

class _WeaknessSection {
  const _WeaknessSection({
    required this.title,
    required this.items,
    this.contentOptionId,
    this.legacyCategoryId,
  });

  final String title;
  final List<WeaknessOption> items;
  final int? contentOptionId;
  final int? legacyCategoryId;

  bool get isLegacy => legacyCategoryId != null;
}
