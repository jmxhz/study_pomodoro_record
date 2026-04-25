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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _SwipeActionCard(
                color: theme.colorScheme.secondaryContainer,
                iconColor: theme.colorScheme.onSecondaryContainer,
                icon: Icons.edit_outlined,
                onTap: onEdit,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _SwipeActionCard(
                color: theme.colorScheme.errorContainer,
                iconColor: theme.colorScheme.onErrorContainer,
                icon: Icons.delete_outline,
                onTap: onDelete,
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

class _SwipeActionCard extends StatelessWidget {
  const _SwipeActionCard({
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.onTap,
  });

  final Color color;
  final Color iconColor;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CustomSlidableAction(
      onPressed: onTap == null ? null : (_) => onTap!.call(),
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 28,
          color: iconColor,
        ),
      ),
    );
  }
}
