import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_services.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/study_type_utils.dart';
import '../../../data/models/life_option.dart';
import '../../../features/settings/pages/settings_home_page_runtime.dart';
import '../controllers/life_record_entry_controller.dart';
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
    if (recordId != null) {
      return _StudyRecordFormHost(
        recordId: recordId,
        embedded: embedded,
      );
    }
    return _RecordModeBody(embedded: embedded);
  }
}

enum RecordSharedMode { study, life }

class RecordSharedModeMemory {
  static RecordSharedMode mode = RecordSharedMode.study;
}

enum _RecordMode { study, life }

class _RecordModeBody extends StatefulWidget {
  const _RecordModeBody({required this.embedded});

  final bool embedded;

  @override
  State<_RecordModeBody> createState() => _RecordModeBodyState();
}

class _RecordModeBodyState extends State<_RecordModeBody> {
  late _RecordMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = RecordSharedModeMemory.mode == RecordSharedMode.life
        ? _RecordMode.life
        : _RecordMode.study;
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _RecordModeSwitch(
            mode: _mode,
            onChanged: (value) {
              setState(() {
                _mode = value;
                RecordSharedModeMemory.mode = value == _RecordMode.life
                    ? RecordSharedMode.life
                    : RecordSharedMode.study;
              });
            },
          ),
        ),
        Expanded(
          child: _mode == _RecordMode.study
              ? const _StudyRecordFormHost(embedded: false)
              : const _LifeRecordFormHost(),
        ),
      ],
    );
    return widget.embedded ? SafeArea(child: body) : body;
  }
}

class _StudyRecordFormHost extends StatelessWidget {
  const _StudyRecordFormHost({
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

class _LifeRecordFormHost extends StatelessWidget {
  const _LifeRecordFormHost();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LifeRecordEntryController>(
      create: (context) {
        final services = context.read<AppServices>();
        return LifeRecordEntryController(
          optionsRepository: services.optionsRepository,
          studyRecordRepository: services.studyRecordRepository,
          dataSyncNotifier: services.dataSyncNotifier,
        );
      },
      child: const _LifeRecordFormBody(),
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
      appBar: AppBar(title: const Text('\u7f16\u8f91\u8bb0\u5f55')),
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
                    const Text('\u8868\u5355\u52a0\u8f7d\u5931\u8d25'),
                    const SizedBox(height: 8),
                    Text(controller.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => controller.load(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('\u91cd\u8bd5'),
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
                      children: const [
                        Icon(Icons.settings_suggest_outlined, size: 40),
                        SizedBox(height: 12),
                        Text(
                            '\u5f53\u524d\u7f3a\u5c11\u53ef\u7528\u914d\u7f6e'),
                        SizedBox(height: 8),
                        Text(
                          '\u8bf7\u5148\u5728\u8bbe\u7f6e\u4e2d\u8865\u5145\u5206\u7c7b\u548c\u5185\u5bb9\u9009\u9879\u3002',
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
                  label: const Text('\u6253\u5f00\u8bbe\u7f6e'),
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
                    _SectionTitle(title: '\u5206\u7c7b'),
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
                    _SectionTitle(title: '\u5185\u5bb9'),
                    const SizedBox(height: 12),
                    _ContentGroups(controller: controller),
                    if (controller
                        .hasLowPointLimitReachedInSelectedCategory) ...[
                      const SizedBox(height: 8),
                      Text(
                        '\u5f53\u524d\u5206\u7c7b\u4e0b\u4f4e\u5206\u5185\u5bb9\u4eca\u65e5\u5df2\u8fbe\u4e0a\u9650\u3002',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _SectionTitle(
                        title: '\u672c\u6b21\u83b7\u5f97\u79ef\u5206'),
                    const SizedBox(height: 8),
                    _PointsSummarySection(controller: controller),
                    const SizedBox(height: 20),
                    _SectionTitle(
                        title: '\u672c\u6b21\u4f11\u606f\u7c7b\u578b'),
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
                            onSelected: (_) => controller.selectBreakItem(item),
                          );
                        }).toList(growable: false),
                      ),
                  ],
                ),
              ),
            ),
            if (controller.selectedContent != null) ...[
              const SizedBox(height: 16),
              _StudyDetailSection(controller: controller),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: '\u65f6\u95f4'),
                    const SizedBox(height: 8),
                    Text(
                      '\u5f53\u524d\u8bb0\u5f55\u65f6\u95f4\uff1a${FormatUtils.formatDateTimeMinute(controller.occurredAt)}',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(context, controller),
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: const Text('\u4fee\u6539\u65e5\u671f'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickTime(context, controller),
                            icon: const Icon(Icons.access_time_outlined),
                            label: const Text('\u4fee\u6539\u65f6\u95f4'),
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
                label: const Text('\u4fdd\u5b58'),
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
                label: const Text('\u4fdd\u5b58\u5e76\u7ee7\u7eed\u65b0\u589e'),
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
                label: const Text('\u4fdd\u5b58\u4fee\u6539'),
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
                ? '\u8bb0\u5f55\u5df2\u66f4\u65b0'
                : continueAdding
                    ? '\u8bb0\u5f55\u5df2\u4fdd\u5b58\uff0c\u53ef\u4ee5\u7ee7\u7eed\u65b0\u589e\u4e0b\u4e00\u6761'
                    : '\u8bb0\u5f55\u5df2\u4fdd\u5b58',
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

class _LifeRecordFormBody extends StatelessWidget {
  const _LifeRecordFormBody();
  static const List<_LifeHabitItem> _habitItems = [
    _LifeHabitItem(
      key: 'neck_shoulder_relax',
      group: '1分',
      title: '肩颈放松',
      points: 1,
      suggestion: '完成肩颈放松，建议 5 分钟以上。',
    ),
    _LifeHabitItem(
      key: 'light_exercise',
      group: '1分',
      title: '轻度锻炼',
      points: 1,
      suggestion: '完成轻度锻炼，建议 10 分钟以上。',
    ),
    _LifeHabitItem(
      key: 'wake_up_leave_bed',
      group: '2分',
      title: '起床后立刻离床',
      points: 2,
      suggestion: '醒来后尽快离床，不继续赖床。',
    ),
    _LifeHabitItem(
      key: 'home_wash_immediately',
      group: '2分',
      title: '回家后立刻洗漱',
      points: 2,
      suggestion: '回家后先洗漱，不先进入娱乐状态。',
    ),
    _LifeHabitItem(
      key: 'morning_no_bed_phone',
      group: '3分',
      title: '早晨未在床上刷视频',
      points: 3,
      suggestion: '醒来后不刷短视频和信息流。',
    ),
    _LifeHabitItem(
      key: 'night_no_video_or_game_binge',
      group: '3分',
      title: '晚上未刷视频/未玩游戏失控',
      points: 3,
      suggestion: '晚上不因视频或游戏拖延洗漱和睡觉。',
    ),
    _LifeHabitItem(
      key: 'in_bed_before_22',
      group: '4分',
      title: '22:00 前上床',
      points: 4,
      suggestion: '22:00 前上床，开始进入睡前状态。',
    ),
    _LifeHabitItem(
      key: 'sleep_before_23_and_no_phone_after_2230',
      group: '4分',
      title: '23:00 前睡觉，且打卡后不再玩手机',
      points: 4,
      suggestion: '22:30 后不刷视频和游戏，23:00 前入睡。',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<LifeRecordEntryController>(
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

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(title: '生活记录项'),
                    const SizedBox(height: 12),
                    FutureBuilder<_LifeHabitSnapshot>(
                      future: _LifePointsSummarySection.loadSnapshot(
                        context: context,
                        selectedHabitKey:
                            _LifePointsSummarySection._resolveHabitKeyStatic(
                                controller.selectedOption?.name),
                        selectedOptionPoints: controller.selectedOption?.points,
                        occurredAt: controller.occurredAt,
                      ),
                      builder: (context, snapshot) {
                        final selectedOption = controller.selectedOption;
                        final completedKeys =
                            snapshot.data?.completedHabitKeys ??
                                const <String>{};
                        final selectedKey =
                            _LifePointsSummarySection._resolveHabitKeyStatic(
                                selectedOption?.name);
                        final selectedBlocked = selectedKey != null &&
                            _LifePointsSummarySection.singleRecordHabitKeys
                                .contains(selectedKey) &&
                            completedKeys.contains(selectedKey);
                        if (selectedBlocked) {
                          final fallback = controller.lifeOptions
                              .where((option) {
                                final key =
                                    _LifePointsSummarySection._resolveHabitKeyStatic(
                                        option.name);
                                if (key == null) {
                                  return true;
                                }
                                final isSingle = _LifePointsSummarySection
                                    .singleRecordHabitKeys
                                    .contains(key);
                                final isDone = completedKeys.contains(key);
                                return !(isSingle && isDone);
                              })
                              .firstOrNull;
                          if (fallback != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!context.mounted) {
                                return;
                              }
                              controller.selectLifeOption(fallback);
                            });
                          }
                        }
                        return _LifeHabitGroups(
                          options: controller.lifeOptions,
                          selectedOption: selectedBlocked ? null : selectedOption,
                          completedHabitKeys: completedKeys,
                          onSelect: controller.selectLifeOption,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _LifePointsSummarySection(
              habits: _habitItems,
              selectedHabitKey:
                  _LifePointsSummarySection._resolveHabitKeyStatic(
                      controller.selectedOption?.name),
              selectedOptionPoints: controller.selectedOption?.points,
              occurredAt: controller.occurredAt,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(title: '备注'),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: controller.setNotes,
                      decoration: const InputDecoration(
                        hintText: '可选：记录执行细节，例如阻碍点、触发动作或替代动作。',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(title: '时间'),
                    const SizedBox(height: 8),
                    Text(
                        '当前记录时间：${FormatUtils.formatDateTimeMinute(controller.occurredAt)}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickLifeDate(context, controller),
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: const Text('修改日期'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickLifeTime(context, controller),
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
            FilledButton.icon(
              onPressed: controller.isSaving
                  ? null
                  : () => _handleLifeSave(context, controller),
              icon: const Icon(Icons.save_outlined),
              label: const Text('保存生活记录'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickLifeDate(
    BuildContext context,
    LifeRecordEntryController controller,
  ) async {
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
    controller.setOccurredAt(
      DateTime(
        date.year,
        date.month,
        date.day,
        controller.occurredAt.hour,
        controller.occurredAt.minute,
      ),
    );
  }

  Future<void> _pickLifeTime(
    BuildContext context,
    LifeRecordEntryController controller,
  ) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(controller.occurredAt),
    );
    if (time == null) {
      return;
    }
    controller.setOccurredAt(
      DateTime(
        controller.occurredAt.year,
        controller.occurredAt.month,
        controller.occurredAt.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _handleLifeSave(
    BuildContext context,
    LifeRecordEntryController controller,
  ) async {
    try {
      final selectedKey = _LifePointsSummarySection._resolveHabitKeyStatic(
          controller.selectedOption?.name);
      final snapshot = await _LifePointsSummarySection.loadSnapshot(
        context: context,
        selectedHabitKey: selectedKey,
        selectedOptionPoints: controller.selectedOption?.points,
        occurredAt: controller.occurredAt,
      );
      if (selectedKey != null &&
          _LifePointsSummarySection.singleRecordHabitKeys
              .contains(selectedKey) &&
          snapshot.completedHabitKeys.contains(selectedKey)) {
        throw StateError('该生活习惯今天已记录，不能重复记录。');
      }
      await controller.save();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('记录已保存')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

}

class _LifeHabitGroups extends StatelessWidget {
  const _LifeHabitGroups({
    required this.options,
    required this.selectedOption,
    required this.completedHabitKeys,
    required this.onSelect,
  });

  final List<LifeOption> options;
  final LifeOption? selectedOption;
  final Set<String> completedHabitKeys;
  final ValueChanged<LifeOption> onSelect;

  @override
  Widget build(BuildContext context) {
    final grouped = <int, List<LifeOption>>{
      1: <LifeOption>[],
      2: <LifeOption>[],
      3: <LifeOption>[],
      4: <LifeOption>[],
    };
    for (final option in options) {
      final score = option.points.clamp(1, 4);
      grouped[score]!.add(option);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [1, 2, 3, 4]
          .where((score) => grouped[score]!.isNotEmpty)
          .map((score) {
        final tier = _lifePointTier(score);
        final items = grouped[score]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${tier.title} · ${score}分',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                tier.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((option) {
                  final key =
                      _LifePointsSummarySection._resolveHabitKeyStatic(option.name);
                  final isSingle = key != null &&
                      _LifePointsSummarySection.singleRecordHabitKeys
                          .contains(key);
                  final isCompletedToday =
                      key != null && completedHabitKeys.contains(key);
                  final canSelect = !(isSingle && isCompletedToday);
                  final selected = selectedOption?.id == option.id &&
                      selectedOption?.name == option.name;
                  return Opacity(
                    opacity: canSelect ? 1 : 0.46,
                    child: ChoiceChip(
                      label: Text('${option.name}（${option.points}分）'),
                      selected: selected,
                      onSelected: canSelect ? (_) => onSelect(option) : null,
                    ),
                  );
                }).toList(growable: false),
              ),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }
}

_LifePointTier _lifePointTier(int score) {
  switch (score) {
    case 1:
      return const _LifePointTier(
        title: '基础维护',
        description: '完成后有帮助，但不是当天生活节奏的关键节点。',
      );
    case 2:
      return const _LifePointTier(
        title: '习惯支撑',
        description: '能明显改善当天状态，但单独完成不一定能扭转节奏。',
      );
    case 3:
      return const _LifePointTier(
        title: '关键节点',
        description: '会影响早晨或晚上的整体走向，是习惯链条中的重要转折点。',
      );
    default:
      return const _LifePointTier(
        title: '核心边界',
        description: '直接对应最想改变的问题，是当天是否失控的核心判断。',
      );
  }
}

class _LifePointTier {
  const _LifePointTier({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

class _LifePointsSummarySection extends StatelessWidget {
  const _LifePointsSummarySection({
    required this.habits,
    required this.selectedHabitKey,
    required this.selectedOptionPoints,
    required this.occurredAt,
  });

  final List<_LifeHabitItem> habits;
  final String? selectedHabitKey;
  final int? selectedOptionPoints;
  final DateTime occurredAt;
  static const Set<String> singleRecordHabitKeys = {
    'wake_up_leave_bed',
    'home_wash_immediately',
    'in_bed_before_22',
    'sleep_before_23_and_no_phone_after_2230',
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LifeHabitSnapshot>(
      future: loadSnapshot(
        context: context,
        selectedHabitKey: selectedHabitKey,
        selectedOptionPoints: selectedOptionPoints,
        occurredAt: occurredAt,
      ),
      builder: (context, snapshot) {
        final selectedPoints = selectedOptionPoints ?? 0;
        final data = snapshot.data ??
            _LifeHabitSnapshot(
              currentPoints: 0,
              currentEarnedPoints: selectedHabitKey == null ? 0 : selectedPoints,
              basePoints: 0,
              bonusPoints: 0,
              completedHabitKeys: const <String>{},
            );
        final rate = ((data.currentPoints / 10) * 100).round();
        final theme = Theme.of(context);
        final feedback = _feedbackText(
          todayPoints: data.currentPoints,
          currentEarnedPoints: data.currentEarnedPoints,
        );
        final reward = _rewardText(
          todayPoints: data.currentPoints,
          currentEarnedPoints: data.currentEarnedPoints,
        );
        final suggestions = _missingSuggestions(data.completedHabitKeys);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(title: '本次生活积分'),
                const SizedBox(height: 2),
                Text(
                  '今日习惯完成情况',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '本次获得：${data.currentEarnedPoints} 分',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('今日生活累计：${data.currentPoints} / 10 分'),
                      const SizedBox(height: 2),
                      Text('今日完成率：$rate%'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  feedback,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
                const SizedBox(height: 8),
                Text(
                  '奖励：$reward',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '建议：',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...suggestions.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• $item',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<_LifeHabitSnapshot> loadSnapshot({
    required BuildContext context,
    required String? selectedHabitKey,
    required int? selectedOptionPoints,
    required DateTime occurredAt,
  }) async {
    final services = context.read<AppServices>();
    final dayStart =
        DateTime(occurredAt.year, occurredAt.month, occurredAt.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final records = await services.studyRecordRepository.getLifeRecordsBetween(
      dayStart,
      dayEnd,
    );
    final completed = <String>{};
    var bonusPoints = 0;
    for (final record in records) {
      final key = _resolveHabitKeyStatic(record.contentNameSnapshot);
      if (key != null) {
        completed.add(key);
      }
      if ((record.points - 2) > bonusPoints) {
        bonusPoints = record.points - 2;
      }
    }
    final selectedAlreadyDone = selectedHabitKey != null &&
        singleRecordHabitKeys.contains(selectedHabitKey) &&
        completed.contains(selectedHabitKey);
    if (completed.length >= 5 && bonusPoints == 0) {
      bonusPoints = 5;
    }
    if (bonusPoints > 5) {
      bonusPoints = 5;
    }
    final basePoints = completed.length * 2;
    return _LifeHabitSnapshot(
      currentPoints: basePoints + bonusPoints,
      currentEarnedPoints:
          selectedAlreadyDone ? 0 : (selectedOptionPoints ?? 0),
      basePoints: basePoints,
      bonusPoints: bonusPoints,
      completedHabitKeys: completed,
    );
  }

  static String? _resolveHabitKeyStatic(String? name) {
    if (name == null || name.trim().isEmpty) {
      return null;
    }
    final normalized = name
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('：', ':')
        .replaceAll('，', ',')
        .toLowerCase();
    if (normalized.contains('起床') && normalized.contains('离床')) {
      return 'wake_up_leave_bed';
    }
    if (normalized.contains('早晨') &&
        normalized.contains('床上') &&
        normalized.contains('刷视频')) {
      return 'morning_no_bed_phone';
    }
    if (normalized.contains('回家') &&
        (normalized.contains('洗漱') || normalized.contains('洗澡')) &&
        (normalized.contains('刷视频') || normalized.contains('游戏'))) {
      return 'home_wash_immediately';
    }
    if (normalized.contains('晚上') &&
        (normalized.contains('刷视频') || normalized.contains('游戏')) &&
        (normalized.contains('失控') || normalized.contains('拖延'))) {
      return 'night_no_video_or_game_binge';
    }
    if (normalized.contains('22:00') ||
        normalized.contains('22点') ||
        normalized.contains('22點')) {
      return 'in_bed_before_22';
    }
    if ((normalized.contains('23:00') ||
            normalized.contains('23点') ||
            normalized.contains('23點')) &&
        normalized.contains('22:30')) {
      return 'sleep_before_23_and_no_phone_after_2230';
    }
    if (normalized.contains('肩颈') ||
        normalized.contains('肩頸') ||
        normalized.contains('锻炼') ||
        normalized.contains('鍛鍊')) {
      if (normalized.contains('肩颈') || normalized.contains('肩頸')) {
        return 'neck_shoulder_relax';
      }
      return 'light_exercise';
    }
    return null;
  }

  List<String> _missingSuggestions(Set<String> completedKeys) {
    final result = <String>[];
    for (final habit in habits) {
      if (!completedKeys.contains(habit.key)) {
        result.add(habit.suggestion);
      }
    }
    return result;
  }

  String _feedbackText({
    required int todayPoints,
    required int currentEarnedPoints,
  }) {
    if (todayPoints <= 2) {
      if (currentEarnedPoints > 0) {
        return '当前只完成了少量习惯，本次记录可以继续把节奏拉起来。';
      }
      return '当前只完成了少量习惯，先优先守住一个最关键动作。';
    }
    if (todayPoints <= 4) {
      if (currentEarnedPoints > 0) {
        return '当前还没过半，本次记录能把今日进度继续往前推。';
      }
      return '当前还没过半，建议再补一条关键生活习惯记录。';
    }
    if (todayPoints <= 6) {
      return '当前已过半，继续保持，优先守住晚间和睡前两个关键动作。';
    }
    if (todayPoints <= 8) {
      return '当前完成度较高，生活节奏在稳定下来。';
    }
    return '当前完成度很高，今天的生活习惯执行很完整。';
  }

  String _rewardText({
    required int todayPoints,
    required int currentEarnedPoints,
  }) {
    if (currentEarnedPoints <= 0) {
      return '本次选择今日已记录或未选择，不会新增积分。';
    }
    if (todayPoints <= 2) {
      return '你保住了今天的最低行动线。';
    }
    if (todayPoints <= 6) {
      return '你在减少无意识刷手机，今晚恢复质量会更好。';
    }
    if (todayPoints <= 8) {
      return '你完成了对身体和注意力的主动维护。';
    }
    return '今天的生活节奏很完整，继续保持低刺激放松。';
  }
}

class _LifeHabitItem {
  const _LifeHabitItem({
    required this.key,
    required this.group,
    required this.title,
    required this.points,
    required this.suggestion,
  });

  final String key;
  final String group;
  final String title;
  final int points;
  final String suggestion;
}

class _LifeHabitSnapshot {
  const _LifeHabitSnapshot({
    required this.currentPoints,
    required this.currentEarnedPoints,
    required this.basePoints,
    required this.bonusPoints,
    required this.completedHabitKeys,
  });

  final int currentPoints;
  final int currentEarnedPoints;
  final int basePoints;
  final int bonusPoints;
  final Set<String> completedHabitKeys;
}

class _RecordModeSwitch extends StatelessWidget {
  const _RecordModeSwitch({
    required this.mode,
    required this.onChanged,
  });

  final _RecordMode mode;
  final ValueChanged<_RecordMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.primary.withValues(alpha: 0.45);
    Widget buildItem(_RecordMode item, String label) {
      final selected = mode == item;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          buildItem(_RecordMode.study, '学习'),
          buildItem(_RecordMode.life, '生活'),
        ],
      ),
    );
  }
}

class _ContentGroups extends StatelessWidget {
  const _ContentGroups({required this.controller});

  final RecordEntryController controller;

  @override
  Widget build(BuildContext context) {
    final grouped = <StudyType, List<dynamic>>{
      for (final type in StudyTypeUtils.orderedTypes) type: <dynamic>[],
    };
    for (final item in controller.contentOptions) {
      final type = StudyTypeUtils.resolveForContent(
        categoryName: controller.selectedCategory?.name,
        contentName: item.name,
        fallbackPoints: item.points,
      );
      grouped[type]!.add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: StudyTypeUtils.orderedTypes
          .where((type) => grouped[type]!.isNotEmpty)
          .map((type) {
        final descriptor = StudyTypeUtils.describe(type);
        final items = grouped[type]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                descriptor.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((item) {
                  final selectable = controller.isContentSelectable(item);
                  return ChoiceChip(
                    label: Text(item.name),
                    selected: controller.selectedContent?.id == item.id,
                    onSelected: selectable
                        ? (_) => controller.selectContent(item)
                        : null,
                  );
                }).toList(growable: false),
              ),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _PointsSummarySection extends StatelessWidget {
  const _PointsSummarySection({required this.controller});

  final RecordEntryController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedType = StudyTypeUtils.describeByPoints(controller.points);
    final dailyCounts = {
      for (final type in StudyTypeUtils.orderedTypes)
        type: controller.dailyCountForType(type),
    };
    final reminder = _buildReminderText(selectedType.type);
    final suggestion = _buildSuggestionText(selectedType.type);
    final plan = _buildPlanText(dailyCounts);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${controller.points}\u5206 \u00b7 ${selectedType.shortLabel}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reminder,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '\u5efa\u8bae\uff1a$suggestion',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '\u4eca\u65e5\u79ef\u5206\u89c4\u5212',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: StudyTypeUtils.orderedTypes.map((type) {
              final descriptor = StudyTypeUtils.describe(type);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
                child: Text(
                  '${descriptor.shortLabel} ${dailyCounts[type]} \u6b21',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 10),
          Text(
            plan,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  String _buildReminderText(StudyType type) {
    switch (type) {
      case StudyType.pureInput:
        return '\u8fdb\u5165\u95e8\u69db\u4f4e\uff0c\u9002\u5408\u70ed\u8eab\u548c\u8865\u5145\uff0c\u4e0d\u9002\u5408\u4f5c\u4e3a\u4eca\u5929\u7684\u4e3b\u529b\u5b66\u4e60\u3002';
      case StudyType.standardPractice:
        return '\u9002\u5408\u505a\u4e3b\u529b\u7ec3\u4e60\uff0c\u80fd\u7a33\u5b9a\u63a8\u8fdb\u8fdb\u5ea6\uff0c\u4f46\u9700\u8981\u540e\u7eed\u8f93\u51fa\u6216\u590d\u76d8\u3002';
      case StudyType.output:
        return '\u80fd\u66b4\u9732\u771f\u5b9e\u638c\u63e1\u60c5\u51b5\uff0c\u5efa\u8bae\u5c3d\u5feb\u914d\u5408\u590d\u76d8\u5de9\u56fa\u3002';
      case StudyType.reviewLoop:
        return '\u5c5e\u4e8e\u9ad8\u4ef7\u503c\u8bb0\u5f55\uff0c\u80fd\u5f62\u6210\u5b8c\u6574\u95ed\u73af\uff0c\u5efa\u8bae\u4f18\u5148\u4fdd\u8bc1\u3002';
    }
  }

  String _buildSuggestionText(StudyType type) {
    switch (type) {
      case StudyType.pureInput:
        return '\u628a\u65f6\u95f4\u7559\u7ed9\u7ec3\u4e60\u3001\u8f93\u51fa\u548c\u590d\u76d8\u3002';
      case StudyType.standardPractice:
        return '\u540e\u7eed\u8865 1 \u6761 3 \u5206\u8f93\u51fa\u6216 4 \u5206\u590d\u76d8\u3002';
      case StudyType.output:
        return '\u8865 1 \u6761 4 \u5206\u590d\u76d8\uff0c\u53ca\u65f6\u7ea0\u9519\u95ed\u73af\u3002';
      case StudyType.reviewLoop:
        return '\u7ee7\u7eed\u4fdd\u6301\uff0c\u540e\u7eed\u6309\u5f53\u524d\u8282\u594f\u63a8\u8fdb\u5373\u53ef\u3002';
    }
  }

  String _buildPlanText(Map<StudyType, int> dailyCounts) {
    if ((dailyCounts[StudyType.reviewLoop] ?? 0) == 0) {
      return '\u8fd9\u6761\u53ef\u4ee5\u5f53\u70ed\u8eab\uff0c\u4f46\u4eca\u5929\u4f18\u5148\u5b8c\u6210 1 \u6761 4 \u5206\u590d\u76d8\u8bb0\u5f55\u3002';
    }
    if ((dailyCounts[StudyType.output] ?? 0) == 0) {
      return '\u5df2\u6709\u590d\u76d8\u57fa\u7840\uff0c\u5efa\u8bae\u518d\u8865 1 \u6761 3 \u5206\u8f93\u51fa\u8bb0\u5f55\u3002';
    }
    final inputCount = dailyCounts[StudyType.pureInput] ?? 0;
    final highValueCount = (dailyCounts[StudyType.standardPractice] ?? 0) +
        (dailyCounts[StudyType.output] ?? 0) +
        (dailyCounts[StudyType.reviewLoop] ?? 0);
    if (inputCount > highValueCount) {
      return '\u5f53\u524d\u8f93\u5165\u8bb0\u5f55\u504f\u591a\uff0c\u4e0b\u4e00\u6761\u5efa\u8bae\u5207\u6362\u5230\u6807\u51c6\u7ec3\u4e60\u6216\u8f93\u51fa\u3002';
    }
    return '\u4eca\u65e5\u79ef\u5206\u7ed3\u6784\u8f83\u5747\u8861\uff0c\u53ef\u4ee5\u6309\u8ba1\u5212\u7ee7\u7eed\u63a8\u8fdb\u3002';
  }
}

class _StudyDetailSection extends StatefulWidget {
  const _StudyDetailSection({required this.controller});

  final RecordEntryController controller;

  @override
  State<_StudyDetailSection> createState() => _StudyDetailSectionState();
}

class _StudyDetailSectionState extends State<_StudyDetailSection> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: '\u8be6\u7ec6\u8bb0\u5f55'),
            const SizedBox(height: 14),
            _DetailExpandableGroup(
              title:
                  '\u5b8c\u6210\u91cf\u3001\u9519\u8bef\u6570\u3001\u5907\u6ce8',
              description: '\u57fa\u7840\u8bb0\u5f55',
              child: Column(
                children: [
                  _BoundTextField(
                    label: '\u5b8c\u6210\u91cf',
                    hintText:
                        '\u4f8b\u5982\uff1a30 \u4e2a\u5355\u8bcd / 1 \u7bc7\u9605\u8bfb / 2 \u9875 / 10 \u5206\u949f',
                    value: controller.primaryAmountValue,
                    onChanged: controller.setDetailAmountText,
                  ),
                  if (controller.showsSecondaryCountField) ...[
                    const SizedBox(height: 12),
                    _BoundTextField(
                      label: '\u9519\u8bef\u6570 / \u5361\u70b9\u6570',
                      hintText:
                          '\u4f8b\u5982\uff1a3\uff08\u6ca1\u6709\u53ef\u4e0d\u586b\uff09',
                      value: controller.wrongCount?.toString() ?? '',
                      keyboardType: TextInputType.number,
                      onChanged: controller.setWrongCount,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _BoundTextField(
                    label: '\u5907\u6ce8',
                    hintText:
                        '\u8bb0\u5f55\u672c\u6b21\u5b66\u4e60\u7684\u5173\u952e\u60c5\u51b5\uff0c\u4f8b\u5982\uff1a\u5361\u5728\u54ea\u91cc\u3001\u4e0b\u6b21\u4f18\u5148\u5904\u7406\u4ec0\u4e48\u3002',
                    value: controller.notes ?? '',
                    onChanged: controller.setNotes,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DetailExpandableGroup(
              title: '\u8584\u5f31\u70b9\u3001\u6539\u8fdb\u63aa\u65bd',
              description: '\u590d\u76d8\u6807\u7b7e',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SingleTagSelector(
                    title: '\u8584\u5f31\u70b9',
                    selectedTag: controller.weaknessTags.isEmpty
                        ? null
                        : controller.weaknessTags.first,
                    options: controller.weaknessOptions
                        .map((item) => item.name)
                        .toList(growable: false),
                    onChanged: controller.setWeaknessTag,
                  ),
                  const SizedBox(height: 12),
                  _SingleTagSelector(
                    title: '\u6539\u8fdb\u63aa\u65bd',
                    selectedTag: controller.improvementTags.isEmpty
                        ? null
                        : controller.improvementTags.first,
                    options: controller.improvementOptions
                        .map((item) => item.name)
                        .toList(growable: false),
                    onChanged: controller.setImprovementTag,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\u9ed8\u8ba4\u6536\u8d77\uff0c\u6309\u9700\u5c55\u5f00\u586b\u5199\u3002',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailExpandableGroup extends StatelessWidget {
  const _DetailExpandableGroup({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tileShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(20, 12, 18, 12),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          shape: tileShape,
          collapsedShape: tileShape,
          iconColor: theme.colorScheme.onSurface,
          collapsedIconColor: theme.colorScheme.onSurface,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                  height: 1.25,
                ),
              ),
            ],
          ),
          children: [
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: double.infinity,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SingleTagSelector extends StatelessWidget {
  const _SingleTagSelector({
    required this.title,
    required this.selectedTag,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final String? selectedTag;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (options.isEmpty)
          Text('\u6682\u65e0\u53ef\u9009\u9879',
              style: Theme.of(context).textTheme.bodySmall)
        else
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((item) {
                return ChoiceChip(
                  label: Text(item),
                  selected: selectedTag == item,
                  onSelected: (selected) => onChanged(selected ? item : null),
                );
              }).toList(growable: false),
            ),
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
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
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
