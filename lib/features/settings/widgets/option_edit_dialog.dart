import 'package:flutter/material.dart';

import '../../../data/models/category_option.dart';

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
  });

  final String name;
  final int? categoryId;
  final bool isEnabled;
}

class SimpleOptionDialog extends StatefulWidget {
  const SimpleOptionDialog({
    super.key,
    required this.title,
    this.initialName = '',
    this.initialEnabled = true,
    this.nameLabel = '名称',
  });

  final String title;
  final String initialName;
  final bool initialEnabled;
  final String nameLabel;

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
  });

  final List<CategoryOption> categories;
  final String initialName;
  final int? initialCategoryId;
  final bool initialEnabled;

  @override
  State<ContentOptionDialog> createState() => _ContentOptionDialogState();
}

class _ContentOptionDialogState extends State<ContentOptionDialog> {
  late final TextEditingController _controller;
  late bool _enabled;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _enabled = widget.initialEnabled;
    _categoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _controller.dispose();
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
            key: ValueKey('content-category-${_categoryId ?? 'all'}'),
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
            decoration: const InputDecoration(labelText: '绑定分类'),
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
              ContentOptionDialogResult(
                name: name,
                categoryId: _categoryId,
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
