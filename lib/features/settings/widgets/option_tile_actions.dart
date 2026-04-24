import 'package:flutter/material.dart';

class OptionTileActions extends StatelessWidget {
  const OptionTileActions({
    super.key,
    required this.isEnabled,
    required this.onEnabledChanged,
    required this.onEdit,
    required this.onDelete,
    this.enabledTooltip = '\u542f\u7528',
    this.editTooltip = '\u7f16\u8f91',
    this.deleteTooltip = '\u5220\u9664',
  });

  final bool isEnabled;
  final ValueChanged<bool>? onEnabledChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String enabledTooltip;
  final String editTooltip;
  final String deleteTooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            height: 38,
            child: Tooltip(
              message: enabledTooltip,
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: editTooltip,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: deleteTooltip,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
