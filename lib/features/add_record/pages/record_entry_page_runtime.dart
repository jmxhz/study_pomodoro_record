import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_services.dart';
import '../../../core/utils/format_utils.dart';
import '../../../features/settings/pages/settings_home_page_runtime.dart';
import '../controllers/record_entry_controller_runtime.dart';

class AddRecordPage extends StatelessWidget {
  const AddRecordPage({
    super.key,
    this.recordId,
    this.embedded = true,
  });

  final int? recordId;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RecordEntryController>(
      create: (context) {
        final services = context.read<AppServices>();
        return RecordEntryController(
          optionsRepository: services.optionsRepository,
          studyRecordRepository: services.studyRecordRepository,
          habitRecordRepository: services.habitRecordRepository,
          dataSyncNotifier: services.dataSyncNotifier,
          recordId: recordId,
        );
      },
      child: _RecordFormBody(
        embedded: embedded,
        recordId: recordId,
      ),
    );
  }
}

class RecordEditPage extends StatelessWidget {
  const RecordEditPage({
    super.key,
    required this.recordId,
  });

  final int recordId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('编辑记录')),
      body: AddRecordPage(recordId: recordId, embedded: false),
    );
  }
}

class _RecordFormBody extends StatelessWidget {
  const _RecordFormBody({
    required this.embedded,
    required this.recordId,
  });

  final bool embedded;
  final int? recordId;

  bool get isEditMode => recordId != null;

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordEntryController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage != null) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40),
                    const SizedBox(height: 12),
                    const Text('表单加载失败'),
                    const SizedBox(height: 8),
                    Text(controller.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => controller.load(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!controller.hasEnabledCategories ||
            !controller.hasEnabledContentOptions) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.settings_suggest_outlined, size: 40),
                        const SizedBox(height: 12),
                        const Text('当前缺少可用配置'),
                        const SizedBox(height: 8),
                        const Text(
                          '请先在设置中补充分类和内容选项。',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const SettingsHomePage()),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('打开设置'),
                ),
              ],
            ),
          );
        }

        final body = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: '分类'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.categories.map((item) {
                        return ChoiceChip(
                          label: Text(item.name),
                          selected: controller.selectedCategory?.id == item.id,
                          onSelected: (_) => controller.selectCategory(item),
                        );
                      }).toList(growable: false),
                    ),
                    const SizedBox(height: 20),
                    _SectionTitle(title: '内容'),
                    const SizedBox(height: 12),
                    _ContentGroups(controller: controller),
                    if (!controller.isLifeMode &&
                        controller
                            .hasLowPointLimitReachedInSelectedCategory) ...[
                      const SizedBox(height: 8),
                      Text(
                        '当前分类下低分内容今日已达上限。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                    if (!controller.isLifeMode) ...[
                      const SizedBox(height: 20),
                      _SectionTitle(title: '本次获得积分'),
                      const SizedBox(height: 8),
                      Text('${controller.points} 分',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 20),
                      _SectionTitle(title: '本次休息类型'),
                      const SizedBox(height: 8),
                      Text(
                        controller.currentBreakTypeLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (controller.breakOptions.isEmpty)
                        Text(
                          controller.currentBreakEmptyMessage,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: controller.breakOptions.map((item) {
                            return ChoiceChip(
                              label: Text(item.name),
                              selected:
                                  controller.selectedBreakItem?.id == item.id,
                              onSelected: (_) =>
                                  controller.selectBreakItem(item),
                            );
                          }).toList(growable: false),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            if (controller.selectedContent != null) ...[
              const SizedBox(height: 16),
              if (controller.isLifeMode)
                _HabitDetailSection(controller: controller)
              else
                _StudyDetailSection(controller: controller),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: '时间'),
                    const SizedBox(height: 8),
                    Text(
                        '当前记录时间：${FormatUtils.formatDateTimeMinute(controller.occurredAt)}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(context, controller),
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: const Text('修改日期'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickTime(context, controller),
                            icon: const Icon(Icons.access_time_outlined),
                            label: const Text('修改时间'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (controller.isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
            if (!isEditMode) ...[
              FilledButton.icon(
                onPressed: controller.isSaving
                    ? null
                    : () => _handleSave(
                          context,
                          controller,
                          continueAdding: false,
                        ),
                icon: const Icon(Icons.save_outlined),
                label: const Text('保存'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: controller.isSaving
                    ? null
                    : () => _handleSave(
                          context,
                          controller,
                          continueAdding: true,
                        ),
                icon: const Icon(Icons.playlist_add_outlined),
                label: const Text('保存并继续新增'),
              ),
            ] else
              FilledButton.icon(
                onPressed: controller.isSaving
                    ? null
                    : () => _handleSave(
                          context,
                          controller,
                          continueAdding: false,
                        ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('保存修改'),
              ),
          ],
        );

        return embedded ? SafeArea(child: body) : body;
      },
    );
  }

  Future<void> _pickDate(
      BuildContext context, RecordEntryController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
    );
    if (date == null) {
      return;
    }
    await controller.setOccurredAt(
      DateTime(
        date.year,
        date.month,
        date.day,
        controller.occurredAt.hour,
        controller.occurredAt.minute,
        controller.occurredAt.second,
      ),
    );
  }

  Future<void> _pickTime(
      BuildContext context, RecordEntryController controller) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(controller.occurredAt),
    );
    if (time == null) {
      return;
    }
    await controller.setOccurredAt(
      DateTime(
        controller.occurredAt.year,
        controller.occurredAt.month,
        controller.occurredAt.day,
        time.hour,
        time.minute,
        controller.occurredAt.second,
      ),
    );
  }

  Future<void> _handleSave(
    BuildContext context,
    RecordEntryController controller, {
    required bool continueAdding,
  }) async {
    try {
      await controller.save(continueAdding: continueAdding);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? '记录已更新'
                : continueAdding
                    ? '记录已保存，可以继续新增下一条'
                    : '记录已保存',
          ),
        ),
      );
      if (isEditMode && !continueAdding) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    }
  }
}

class _ContentGroups extends StatelessWidget {
  const _ContentGroups({required this.controller});

  final RecordEntryController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: controller.contentOptions.map((item) {
        final selectable =
            controller.isLifeMode ? true : controller.isContentSelectable(item);
        return ChoiceChip(
          label: Text(item.name),
          selected: controller.selectedContent?.id == item.id,
          onSelected: selectable ? (_) => controller.selectContent(item) : null,
        );
      }).toList(growable: false),
    );
  }
}

class _HabitDetailSection extends StatelessWidget {
  const _HabitDetailSection({required this.controller});

  final RecordEntryController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: '生活记录'),
            const SizedBox(height: 12),
            Text('完成状态', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('已完成'),
                  selected: controller.habitCompleted,
                  onSelected: (_) => controller.setHabitCompleted(true),
                ),
                ChoiceChip(
                  label: const Text('未完成'),
                  selected: !controller.habitCompleted,
                  onSelected: (_) => controller.setHabitCompleted(false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BoundTextField(
              label: '时长（分钟，可选）',
              value: controller.habitDurationMinutes?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: controller.setHabitDurationMinutes,
            ),
            const SizedBox(height: 12),
            _BoundTextField(
              label: '备注（可选）',
              value: controller.habitNotes ?? '',
              onChanged: controller.setHabitNotes,
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyDetailSection extends StatelessWidget {
  const _StudyDetailSection({required this.controller});

  final RecordEntryController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: '详细记录'),
            const SizedBox(height: 12),
            _BoundTextField(
              label: '完成量',
              hintText: '例如：10个单词 / 1篇阅读 / 2页 / 10分钟',
              value: controller.primaryAmountValue,
              onChanged: controller.setDetailAmountText,
            ),
            if (controller.showsSecondaryCountField) ...[
              const SizedBox(height: 12),
              _BoundTextField(
                label: '错误数 / 卡点数',
                value: controller.wrongCount?.toString() ?? '',
                keyboardType: TextInputType.number,
                onChanged: controller.setWrongCount,
              ),
            ],
            const SizedBox(height: 12),
            _TagSelector(
              title: '薄弱点（最多2项）',
              selectedTags: controller.weaknessTags,
              options: controller.weaknessOptions
                  .map((item) => item.name)
                  .toList(growable: false),
              onToggle: controller.toggleWeaknessTag,
            ),
            const SizedBox(height: 12),
            _TagSelector(
              title: '改进措施（最多2项）',
              selectedTags: controller.improvementTags,
              options: controller.improvementOptions
                  .map((item) => item.name)
                  .toList(growable: false),
              onToggle: controller.toggleImprovementTag,
            ),
            const SizedBox(height: 12),
            _BoundTextField(
              label: '备注',
              value: controller.notes ?? '',
              onChanged: controller.setNotes,
            ),
          ],
        ),
      ),
    );
  }
}

class _TagSelector extends StatelessWidget {
  const _TagSelector({
    required this.title,
    required this.selectedTags,
    required this.options,
    required this.onToggle,
  });

  final String title;
  final List<String> selectedTags;
  final List<String> options;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (options.isEmpty)
          Text('暂无可选项', style: Theme.of(context).textTheme.bodySmall)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((item) {
              return FilterChip(
                label: Text(item),
                selected: selectedTags.contains(item),
                onSelected: (_) {
                  if (!selectedTags.contains(item) &&
                      selectedTags.length >= 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('最多选择 2 项')),
                    );
                    return;
                  }
                  onToggle(item);
                },
              );
            }).toList(growable: false),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _BoundTextField extends StatefulWidget {
  const _BoundTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hintText,
    this.keyboardType,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final TextInputType? keyboardType;

  @override
  State<_BoundTextField> createState() => _BoundTextFieldState();
}

class _BoundTextFieldState extends State<_BoundTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _BoundTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
      ),
    );
  }
}
