import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/life_option.dart';
import '../controllers/settings_controller_runtime.dart';
import '../widgets/option_tile_actions.dart';

class ManageLifeOptionsPage extends StatelessWidget {
  const ManageLifeOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        final sortedOptions = [...controller.lifeOptions]..sort((a, b) {
            final pointsCompare = a.points.compareTo(b.points);
            if (pointsCompare != 0) {
              return pointsCompare;
            }
            return a.name.compareTo(b.name);
          });

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
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.flag_outlined),
                            title: const Text('每日生活目标分'),
                            subtitle: Text(
                              '达到 ${controller.lifeDailyTargetPoints} 分视为达标',
                            ),
                            trailing: IconButton(
                              tooltip: '修改',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: controller.isBusy
                                  ? null
                                  : () => _editLifeTargetPoints(
                                      context, controller),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.add_card_outlined),
                            title: const Text('达标奖励分'),
                            subtitle: Text(
                              '每日达标后额外奖励 ${controller.lifeDailyTargetBonusPoints} 分',
                            ),
                            trailing: IconButton(
                              tooltip: '修改',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: controller.isBusy
                                  ? null
                                  : () =>
                                      _editLifeBonusPoints(context, controller),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (sortedOptions.isEmpty)
                      const Center(child: Text('暂无生活记录项'))
                    else
                      ...sortedOptions.map(
                        (item) => Card(
                          child: ListTile(
                            title: Text(item.name),
                            subtitle: Text(
                              '${item.isEnabled ? '已启用' : '已停用'} · ${item.points} 分',
                            ),
                            trailing: OptionTileActions(
                              isEnabled: item.isEnabled,
                              onEnabledChanged: controller.isBusy
                                  ? null
                                  : (value) => controller.updateLifeOption(
                                        item.copyWith(isEnabled: value),
                                      ),
                              onEdit: () =>
                                  _editLifeOption(context, controller, item),
                              onDelete: () =>
                                  _deleteLifeOption(context, controller, item),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editLifeTargetPoints(
    BuildContext context,
    SettingsController controller,
  ) async {
    final value = await _showIntInputDialog(
      context: context,
      title: '每日生活目标分',
      label: '目标分',
      initialValue: controller.lifeDailyTargetPoints,
      minValue: 1,
      maxValue: 100,
    );
    if (value == null) {
      return;
    }
    await controller.setLifeDailyTargetPointsValue(value);
  }

  Future<void> _editLifeBonusPoints(
    BuildContext context,
    SettingsController controller,
  ) async {
    final value = await _showIntInputDialog(
      context: context,
      title: '达标奖励分',
      label: '奖励分',
      initialValue: controller.lifeDailyTargetBonusPoints,
      minValue: 0,
      maxValue: 100,
    );
    if (value == null) {
      return;
    }
    await controller.setLifeDailyTargetBonusPointsValue(value);
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
      isEnabled: true,
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
      ),
    );
    if (result == null) {
      return;
    }
    await controller.updateLifeOption(
      item.copyWith(
        name: result.name,
        points: result.points,
        isEnabled: item.isEnabled,
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

  Future<int?> _showIntInputDialog({
    required BuildContext context,
    required String title,
    required String label,
    required int initialValue,
    required int minValue,
    required int maxValue,
  }) async {
    final controller = TextEditingController(text: '$initialValue');
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '$label（$minValue-$maxValue）',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null || value < minValue || value > maxValue) {
                  return;
                }
                Navigator.of(context).pop(value);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }
}

class _LifeOptionDialogResult {
  const _LifeOptionDialogResult({
    required this.name,
    required this.points,
  });

  final String name;
  final int points;
}

class _LifeOptionDialog extends StatefulWidget {
  const _LifeOptionDialog({
    this.initialName = '',
    this.initialPoints = 3,
  });

  final String initialName;
  final int initialPoints;

  @override
  State<_LifeOptionDialog> createState() => _LifeOptionDialogState();
}

class _LifeOptionDialogState extends State<_LifeOptionDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _pointsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _pointsController = TextEditingController(text: '${widget.initialPoints}');
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
              ),
            );
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
