import 'package:flutter/material.dart';

import '../../../data/models/category_option.dart';
import '../../../data/models/content_option.dart';

class SimpleOptionDialogResult {
  const SimpleOptionDialogResult({
    required this.name,
    required this.isEnabled,
  });

  final String name;
  final bool isEnabled;
}

class CategoryBoundOptionDialogResult {
  const CategoryBoundOptionDialogResult({
    required this.name,
    required this.categoryId,
    required this.isEnabled,
  });

  final String name;
  final int? categoryId;
  final bool isEnabled;
}

class ContentBoundOptionDialogResult {
  const ContentBoundOptionDialogResult({
    required this.name,
    required this.contentOptionId,
    required this.isEnabled,
  });

  final String name;
  final int? contentOptionId;
  final bool isEnabled;
}

class ContentOptionDialogResult {
  const ContentOptionDialogResult({
    required this.name,
    required this.categoryId,
    required this.isEnabled,
    required this.points,
  });

  final String name;
  final int? categoryId;
  final bool isEnabled;
  final int points;
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
  late final TextEditingController _nameController;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _isEnabled = widget.initialEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(labelText: widget.nameLabel),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('启用'),
            value: _isEnabled,
            onChanged: (value) {
              setState(() {
                _isEnabled = value;
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
            if (name.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              SimpleOptionDialogResult(
                name: name,
                isEnabled: _isEnabled,
              ),
            );
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class CategoryBoundOptionDialog extends StatefulWidget {
  const CategoryBoundOptionDialog({
    super.key,
    required this.title,
    required this.nameLabel,
    required this.categories,
    this.initialName = '',
    this.initialCategoryId,
    this.initialEnabled = true,
  });

  final String title;
  final String nameLabel;
  final List<CategoryOption> categories;
  final String initialName;
  final int? initialCategoryId;
  final bool initialEnabled;

  @override
  State<CategoryBoundOptionDialog> createState() => _CategoryBoundOptionDialogState();
}

class _CategoryBoundOptionDialogState extends State<CategoryBoundOptionDialog> {
  late final TextEditingController _nameController;
  late bool _isEnabled;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _isEnabled = widget.initialEnabled;
    _categoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(labelText: widget.nameLabel),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: '绑定分类'),
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
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('启用'),
            value: _isEnabled,
            onChanged: (value) {
              setState(() {
                _isEnabled = value;
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
            if (name.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              CategoryBoundOptionDialogResult(
                name: name,
                categoryId: _categoryId,
                isEnabled: _isEnabled,
              ),
            );
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class ContentBoundOptionDialog extends StatefulWidget {
  const ContentBoundOptionDialog({
    super.key,
    required this.title,
    required this.nameLabel,
    required this.contentOptions,
    this.initialName = '',
    this.initialContentOptionId,
    this.initialEnabled = true,
  });

  final String title;
  final String nameLabel;
  final List<ContentOption> contentOptions;
  final String initialName;
  final int? initialContentOptionId;
  final bool initialEnabled;

  @override
  State<ContentBoundOptionDialog> createState() => _ContentBoundOptionDialogState();
}

class _ContentBoundOptionDialogState extends State<ContentBoundOptionDialog> {
  late final TextEditingController _nameController;
  late bool _isEnabled;
  int? _contentOptionId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _isEnabled = widget.initialEnabled;
    _contentOptionId = widget.initialContentOptionId;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(labelText: widget.nameLabel),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _contentOptionId,
            decoration: const InputDecoration(labelText: '绑定内容'),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('不绑定内容'),
              ),
              ...widget.contentOptions.map(
                (item) => DropdownMenuItem<int?>(
                  value: item.id,
                  child: Text(item.name),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _contentOptionId = value;
              });
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('启用'),
            value: _isEnabled,
            onChanged: (value) {
              setState(() {
                _isEnabled = value;
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
            if (name.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              ContentBoundOptionDialogResult(
                name: name,
                contentOptionId: _contentOptionId,
                isEnabled: _isEnabled,
              ),
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
    this.initialPoints = 1,
  });

  final List<CategoryOption> categories;
  final String initialName;
  final int? initialCategoryId;
  final bool initialEnabled;
  final int initialPoints;

  @override
  State<ContentOptionDialog> createState() => _ContentOptionDialogState();
}

class _ContentOptionDialogState extends State<ContentOptionDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _pointsController;
  late bool _isEnabled;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _pointsController = TextEditingController(
      text: widget.initialPoints.toString(),
    );
    _isEnabled = widget.initialEnabled;
    _categoryId = widget.initialCategoryId;
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
      title: const Text('内容配置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: '内容名称'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: '所属分类'),
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
              value: _isEnabled,
              onChanged: (value) {
                setState(() {
                  _isEnabled = value;
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
            final points = int.tryParse(_pointsController.text.trim());
            if (name.isEmpty || points == null || points < 1) {
              return;
            }
            Navigator.of(context).pop(
              ContentOptionDialogResult(
                name: name,
                categoryId: _categoryId,
                isEnabled: _isEnabled,
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
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _costPointsController = TextEditingController(
      text: widget.initialCostPoints.toString(),
    );
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _isEnabled = widget.initialEnabled;
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
              value: _isEnabled,
              onChanged: (value) {
                setState(() {
                  _isEnabled = value;
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
                isEnabled: _isEnabled,
              ),
            );
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
