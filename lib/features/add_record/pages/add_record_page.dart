import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_services.dart';
import '../../../core/utils/format_utils.dart';
import '../../../data/models/reward_option.dart';
import '../../../features/settings/pages/settings_page.dart';
import '../../../shared/widgets/state_views.dart';
import '../controllers/record_form_controller.dart';

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
    return ChangeNotifierProvider<RecordFormController>(
      create: (context) {
        final services = context.read<AppServices>();
        return RecordFormController(
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
      body: AddRecordPage(
        recordId: recordId,
        embedded: false,
      ),
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
    return Consumer<RecordFormController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const LoadingView(message: '正在加载表单数据...');
        }

        if (controller.errorMessage != null) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ErrorStateCard(
              message: controller.errorMessage!,
              onRetry: () => controller.load(),
            ),
          );
        }

        if (!controller.hasEnabledCategories ||
            !controller.hasEnabledContentOptions ||
            !controller.hasEnabledRewardOptions) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const EmptyStateCard(
                  title: '当前没有可用配置',
                  subtitle: '请先到设置中补充分类、内容或奖励选项。',
                  icon: Icons.settings_suggest_outlined,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsPage(),
                      ),
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
                    Text('分类', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          controller.categories.map((item) {
                            return ChoiceChip(
                              label: Text(item.name),
                              selected: controller.selectedCategory?.id == item.id &&
                                  controller.selectedCategory?.name == item.name,
                              onSelected: (_) => controller.selectCategory(item),
                            );
                          }).toList(growable: false),
                    ),
                    const SizedBox(height: 20),
                    Text('内容', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          controller.contentOptions.map((item) {
                            return ChoiceChip(
                              label: Text(item.name),
                              selected:
                                  controller.selectedContent?.id == item.id &&
                                  controller.selectedContent?.name == item.name,
                              onSelected: (_) => controller.selectContent(item),
                            );
                          }).toList(growable: false),
                    ),
                    const SizedBox(height: 20),
                    Text('番茄钟数', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _NumberChipGroup(
                      value: controller.pomodoroCount,
                      onChanged: controller.setPomodoroCount,
                    ),
                    const SizedBox(height: 20),
                    Text('积分数', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _NumberChipGroup(
                      value: controller.points,
                      onChanged: controller.setPoints,
                    ),
                    const SizedBox(height: 20),
                    Text('奖励内容', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      key: ValueKey(
                        'reward-${controller.selectedReward?.id}-${controller.selectedReward?.name}',
                      ),
                      initialValue: controller.selectedReward,
                      isExpanded: true,
                      items:
                          controller.rewardOptions.map((item) {
                            return DropdownMenuItem<RewardOption>(
                              value: item,
                              child: Text(item.name),
                            );
                          }).toList(growable: false),
                      onChanged: controller.selectReward,
                      decoration: const InputDecoration(
                        labelText: '选择奖励内容',
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
                    Text('时间', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      '当前记录时间：${FormatUtils.formatDateTime(controller.occurredAt)}',
                    ),
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
                onPressed:
                    controller.isSaving
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
                onPressed:
                    controller.isSaving
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
                onPressed:
                    controller.isSaving
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

        if (embedded) {
          return SafeArea(child: body);
        }
        return body;
      },
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    RecordFormController controller,
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

  Future<void> _pickTime(
    BuildContext context,
    RecordFormController controller,
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

  Future<void> _handleSave(
    BuildContext context,
    RecordFormController controller,
    {required bool continueAdding}
  ) async {
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
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    }
  }
}

class _NumberChipGroup extends StatelessWidget {
  const _NumberChipGroup({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          List.generate(4, (index) => index + 1).map((item) {
            return ChoiceChip(
              label: Text('$item'),
              selected: value == item,
              onSelected: (_) => onChanged(item),
            );
          }).toList(growable: false),
    );
  }
}
