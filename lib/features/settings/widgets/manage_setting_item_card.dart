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
        motion: const BehindMotion(),
        extentRatio: 0.42,
        children: [
          CustomSlidableAction(
            onPressed: onEdit == null ? null : (_) => onEdit!.call(),
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
            padding: EdgeInsets.zero,
            autoClose: true,
            child: Center(
              child: Icon(
                Icons.edit_outlined,
                size: 30,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          CustomSlidableAction(
            onPressed: onDelete == null ? null : (_) => onDelete!.call(),
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.onErrorContainer,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            padding: EdgeInsets.zero,
            autoClose: true,
            child: Center(
              child: Icon(
                Icons.delete_outline,
                size: 30,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 28,
                child: Align(
                  alignment: Alignment.center,
                  child: dragHandle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    for (var i = 0; i < detailLines.length; i++) ...[
                      Text(
                        detailLines[i],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
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
                width: 78,
                child: Align(
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scale: 0.95,
                    child: Switch(
                      value: isEnabled,
                      onChanged: onEnabledChanged,
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
