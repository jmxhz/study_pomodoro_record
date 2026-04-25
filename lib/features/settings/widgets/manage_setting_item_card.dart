import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.42,
        children: [
          SlidableAction(
            onPressed: onEdit == null ? null : (_) => onEdit!.call(),
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            icon: Icons.edit_outlined,
            label: '编辑',
          ),
          SlidableAction(
            onPressed: onDelete == null ? null : (_) => onDelete!.call(),
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.onErrorContainer,
            icon: Icons.delete_outline,
            label: '删除',
          ),
        ],
      ),
      child: Card(
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
                child: Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
