import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/life_option.dart';
import '../controllers/settings_controller_runtime.dart';

class ManageLifeOptionsPage extends StatelessWidget {
  const ManageLifeOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('生活记录项'),
            actions: [
              IconButton(
                tooltip: '新增',
                onPressed: controller.isBusy
                    ? null
                    : () => _addLifeOption(context, controller),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: Column(
            children: [
              if (controller.isBusy) const LinearProgressIndicator(),
              Expanded(
                child: controller.lifeOptions.isEmpty
                    ? const Center(child: Text('暂无生活记录项'))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.lifeOptions.length,
                        onReorder: controller.reorderLifeOptions,
                        itemBuilder: (context, index) {
                          final item = controller.lifeOptions[index];
                          return Card(
                            key: ValueKey('life-${item.id ?? item.name}'),
                            child: ListTile(
                              leading: const Icon(Icons.drag_indicator),
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.isEnabled ? '已启用' : '已停用'} · ${item.points} 分',
                              ),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    tooltip: '编辑',
                                    onPressed: () => _editLifeOption(
                                        context, controller, item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: '删除',
                                    onPressed: () => _deleteLifeOption(
                                        context, controller, item),
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

  Future<void> _addLifeOption(
    BuildContext context,
    SettingsController controller,
  ) async {
    final result = await showDialog<_LifeOptionDialogResult>(
      context: context,
      builder: (context) => const _LifeOptionDialog(),
    );
    if (result == null) {
      return;
    }
    await controller.addLifeOption(
      name: result.name,
      points: result.points,
      isEnabled: result.isEnabled,
    );
  }

  Future<void> _editLifeOption(
    BuildContext context,
    SettingsController controller,
    LifeOption item,
  ) async {
    final result = await showDialog<_LifeOptionDialogResult>(
      context: context,
      builder: (context) => _LifeOptionDialog(
        initialName: item.name,
        initialPoints: item.points,
        initialEnabled: item.isEnabled,
      ),
    );
    if (result == null) {
      return;
    }
    await controller.updateLifeOption(
      item.copyWith(
        name: result.name,
        points: result.points,
        isEnabled: result.isEnabled,
      ),
    );
  }

  Future<void> _deleteLifeOption(
    BuildContext context,
    SettingsController controller,
    LifeOption item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除生活记录项'),
          content: Text('删除“${item.name}”后，不影响已有历史记录。确认继续吗？'),
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
      await controller.deleteLifeOption(item);
    }
  }
}

class _LifeOptionDialogResult {
  const _LifeOptionDialogResult({
    required this.name,
    required this.points,
    required this.isEnabled,
  });

  final String name;
  final int points;
  final bool isEnabled;
}

class _LifeOptionDialog extends StatefulWidget {
  const _LifeOptionDialog({
    this.initialName = '',
    this.initialPoints = 3,
    this.initialEnabled = true,
  });

  final String initialName;
  final int initialPoints;
  final bool initialEnabled;

  @override
  State<_LifeOptionDialog> createState() => _LifeOptionDialogState();
}

class _LifeOptionDialogState extends State<_LifeOptionDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _pointsController;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _pointsController = TextEditingController(text: '${widget.initialPoints}');
    _enabled = widget.initialEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('生活记录项配置'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: '名称'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '积分'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('启用'),
            value: _enabled,
            onChanged: (value) {
              setState(() {
                _enabled = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final points = int.tryParse(_pointsController.text.trim());
            if (name.isEmpty || points == null || points <= 0) {
              return;
            }
            Navigator.of(context).pop(
              _LifeOptionDialogResult(
                name: name,
                points: points,
                isEnabled: _enabled,
              ),
            );
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
