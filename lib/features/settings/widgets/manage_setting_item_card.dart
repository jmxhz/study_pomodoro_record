import 'package:flutter/material.dart';

enum _ManageItemAction { edit, delete }

class ManageSettingItemCard extends StatelessWidget {
  const ManageSettingItemCard({
    super.key,
    required this.dragHandle,
    required this.title,
    required this.detailLines,
    required this.isEnabled,
    required this.onEnabledChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final Widget dragHandle;
  final String title;
  final List<String> detailLines;
  final bool isEnabled;
  final ValueChanged<bool>? onEnabledChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Align(
                alignment: Alignment.topCenter,
                child: dragHandle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  for (var i = 0; i < detailLines.length; i++) ...[
                    Text(
                      detailLines[i],
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                    if (i < detailLines.length - 1) const SizedBox(height: 2),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 38,
                    child: Transform.scale(
                      scale: 0.86,
                      alignment: Alignment.centerRight,
                      child: Switch(
                        value: isEnabled,
                        onChanged: onEnabledChanged,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PopupMenuButton<_ManageItemAction>(
                    tooltip: '更多操作',
                    icon: const Icon(Icons.more_horiz_rounded),
                    onSelected: (action) {
                      if (action == _ManageItemAction.edit) {
                        onEdit?.call();
                        return;
                      }
                      onDelete?.call();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<_ManageItemAction>(
                        value: _ManageItemAction.edit,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('编辑'),
                        ),
                      ),
                      PopupMenuItem<_ManageItemAction>(
                        value: _ManageItemAction.delete,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Icon(Icons.delete_outline),
                          title: Text('删除'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
