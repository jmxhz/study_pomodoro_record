import 'package:flutter/material.dart';

import '../../../data/models/category_option.dart';
import '../../../data/models/reward_rule.dart';

class SimpleOptionDialogResult {
  const SimpleOptionDialogResult({
    required this.name,
    required this.isEnabled,
  });

  final String name;
  final bool isEnabled;
}

class ContentOptionDialogResult {
  const ContentOptionDialogResult({
    required this.name,
    required this.categoryId,
    required this.isEnabled,
    required this.defaultPoints,
    required this.allowAdjust,
    required this.minPoints,
    required this.maxPoints,
  });

  final String name;
  final int? categoryId;
  final bool isEnabled;
  final int defaultPoints;
  final bool allowAdjust;
  final int minPoints;
  final int maxPoints;
}

class RewardRuleDialogResult {
  const RewardRuleDialogResult({
    required this.name,
    required this.periodType,
    required this.thresholdPoints,
    required this.rewardText,
    required this.isEnabled,
  });

  final String name;
  final RewardRulePeriodType periodType;
  final int thresholdPoints;
  final String rewardText;
  final bool isEnabled;
}

class RedeemRewardDialogResult {
  const RedeemRewardDialogResult({
    required this.name,
    required this.costPoints,
    required this.note,
    required this.isEnabled,
  });

  final String name;
  final int costPoints;
  final String? note;
  final bool isEnabled;
}

class SimpleOptionDialog extends StatefulWidget {
  const SimpleOptionDialog({
    super.key,
    required this.title,
    required this.nameLabel,
    this.initialName = '',
    this.initialEnabled = true,
  });

  final String title;
  final String nameLabel;
  final String initialName;
  final bool initialEnabled;

  @override
  State<SimpleOptionDialog> createState() => _SimpleOptionDialogState();
}

class _SimpleOptionDialogState extends State<SimpleOptionDialog> {
  late final TextEditingController _controller;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _enabled = widget.initialEnabled;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(labelText: widget.nameLabel),
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
            final name = _controller.text.trim();
            if (name.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              SimpleOptionDialogResult(name: name, isEnabled: _enabled),
            );
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class ContentOptionDialog extends StatefulWidget {
  const ContentOptionDialog({
    super.key,
    required this.categories,
    this.initialName = '',
    this.initialCategoryId,
    this.initialEnabled = true,
    this.initialDefaultPoints = 1,
    this.initialAllowAdjust = true,
    this.initialMinPoints = 1,
    this.initialMaxPoints = 4,
  });

  final List<CategoryOption> categories;
  final String initialName;
  final int? initialCategoryId;
  final bool initialEnabled;
  final int initialDefaultPoints;
  final bool initialAllowAdjust;
  final int initialMinPoints;
  final int initialMaxPoints;

  @override
  State<ContentOptionDialog> createState() => _ContentOptionDialogState();
}

class _ContentOptionDialogState extends State<ContentOptionDialog> {
  late final TextEditingController _controller;
  late final TextEditingController _defaultPointsController;
  late final TextEditingController _minPointsController;
  late final TextEditingController _maxPointsController;
  late bool _enabled;
  late bool _allowAdjust;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _defaultPointsController = TextEditingController(
      text: widget.initialDefaultPoints.toString(),
    );
    _minPointsController = TextEditingController(
      text: widget.initialMinPoints.toString(),
    );
    _maxPointsController = TextEditingController(
      text: widget.initialMaxPoints.toString(),
    );
    _enabled = widget.initialEnabled;
    _allowAdjust = widget.initialAllowAdjust;
    _categoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _controller.dispose();
    _defaultPointsController.dispose();
    _minPointsController.dispose();
    _maxPointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('内容配置'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: '内容名称'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _categoryId,
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('全部分类'),
              ),
              ...widget.categories.map(
                (item) => DropdownMenuItem<int?>(
                  value: item.id,
                  child: Text(item.name),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _categoryId = value;
              });
            },
            decoration: const InputDecoration(labelText: '所属分类'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _defaultPointsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '默认积分'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('允许微调积分'),
            value: _allowAdjust,
            onChanged: (value) {
              setState(() {
                _allowAdjust = value;
              });
            },
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '最小积分'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxPointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '最大积分'),
                ),
              ),
            ],
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
            final name = _controller.text.trim();
            final defaultPoints = int.tryParse(_defaultPointsController.text.trim());
            final minPoints = int.tryParse(_minPointsController.text.trim());
            final maxPoints = int.tryParse(_maxPointsController.text.trim());
            if (name.isEmpty ||
                defaultPoints == null ||
                minPoints == null ||
                maxPoints == null ||
                minPoints > maxPoints ||
                defaultPoints < minPoints ||
                defaultPoints > maxPoints) {
              return;
            }
            Navigator.of(context).pop(
              ContentOptionDialogResult(
                name: name,
                categoryId: _categoryId,
                isEnabled: _enabled,
                defaultPoints: defaultPoints,
                allowAdjust: _allowAdjust,
                minPoints: minPoints,
                maxPoints: maxPoints,
              ),
            );
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class RedeemRewardDialog extends StatefulWidget {
  const RedeemRewardDialog({
    super.key,
    this.initialName = '',
    this.initialCostPoints = 1,
    this.initialNote,
    this.initialEnabled = true,
  });

  final String initialName;
  final int initialCostPoints;
  final String? initialNote;
  final bool initialEnabled;

  @override
  State<RedeemRewardDialog> createState() => _RedeemRewardDialogState();
}

class _RedeemRewardDialogState extends State<RedeemRewardDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _costPointsController;
  late final TextEditingController _noteController;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _costPointsController = TextEditingController(
      text: widget.initialCostPoints.toString(),
    );
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _enabled = widget.initialEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costPointsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('奖励兑换项'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: '奖励名称'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _costPointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '所需积分'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: '备注'),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final costPoints = int.tryParse(_costPointsController.text.trim());
            if (name.isEmpty || costPoints == null || costPoints < 1) {
              return;
            }
            final note = _noteController.text.trim();
            Navigator.of(context).pop(
              RedeemRewardDialogResult(
                name: name,
                costPoints: costPoints,
                note: note.isEmpty ? null : note,
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

class RewardRuleDialog extends StatefulWidget {
  const RewardRuleDialog({
    super.key,
    this.initialName = '',
    this.initialPeriodType = RewardRulePeriodType.day,
    this.initialThresholdPoints = 4,
    this.initialRewardText = '',
    this.initialEnabled = true,
  });

  final String initialName;
  final RewardRulePeriodType initialPeriodType;
  final int initialThresholdPoints;
  final String initialRewardText;
  final bool initialEnabled;

  @override
  State<RewardRuleDialog> createState() => _RewardRuleDialogState();
}

class _RewardRuleDialogState extends State<RewardRuleDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _rewardTextController;
  late RewardRulePeriodType _periodType;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _thresholdController = TextEditingController(
      text: widget.initialThresholdPoints.toString(),
    );
    _rewardTextController = TextEditingController(text: widget.initialRewardText);
    _periodType = widget.initialPeriodType;
    _enabled = widget.initialEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _thresholdController.dispose();
    _rewardTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('阶段奖励规则'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: '规则名称'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RewardRulePeriodType>(
              initialValue: _periodType,
              decoration: const InputDecoration(labelText: '周期类型'),
              items: RewardRulePeriodType.values
                  .map(
                    (item) => DropdownMenuItem<RewardRulePeriodType>(
                      value: item,
                      child: Text(item.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _periodType = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _thresholdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '触发积分'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rewardTextController,
              decoration: const InputDecoration(labelText: '奖励说明'),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final rewardText = _rewardTextController.text.trim();
            final thresholdPoints = int.tryParse(_thresholdController.text.trim());
            if (name.isEmpty || rewardText.isEmpty || thresholdPoints == null) {
              return;
            }
            Navigator.of(context).pop(
              RewardRuleDialogResult(
                name: name,
                periodType: _periodType,
                thresholdPoints: thresholdPoints,
                rewardText: rewardText,
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
