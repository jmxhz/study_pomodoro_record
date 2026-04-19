import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_services.dart';
import '../../../data/repositories/csv_service.dart';
import '../../../shared/services/native_share_service.dart';
import '../controllers/settings_controller.dart';
import 'manage_categories_clean_page.dart';
import 'manage_contents_clean_page.dart';
import 'manage_feedback_page.dart';
import 'manage_improvement_options_page.dart';
import 'manage_redeem_rewards_page.dart';
import 'manage_weakness_options_page.dart';

class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsController>(
      create: (context) {
        final services = context.read<AppServices>();
        return SettingsController(
          optionsRepository: services.optionsRepository,
          csvService: services.csvService,
          dataSyncNotifier: services.dataSyncNotifier,
        );
      },
      child: const _SettingsBody(),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('设置')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (controller.isBusy) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
              ],
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: const Text('分类管理'),
                      subtitle: Text('当前 ${controller.categories.length} 项'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: controller,
                            child: const ManageCategoriesCleanPage(),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.book_outlined),
                      title: const Text('内容管理'),
                      subtitle: Text('当前 ${controller.contentOptions.length} 项'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: controller,
                            child: const ManageContentsCleanPage(),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.self_improvement_outlined),
                      title: const Text('本轮反馈管理'),
                      subtitle: Text('当前 ${controller.rewardOptions.length} 项'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: controller,
                            child: const ManageFeedbackPage(),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.report_problem_outlined),
                      title: const Text('薄弱点管理'),
                      subtitle: Text('当前 ${controller.weaknessOptions.length} 项'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: controller,
                            child: const ManageWeaknessOptionsPage(),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.build_circle_outlined),
                      title: const Text('改进措施管理'),
                      subtitle: Text('当前 ${controller.improvementOptions.length} 项'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: controller,
                            child: const ManageImprovementOptionsPage(),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.redeem_outlined),
                      title: const Text('奖励兑换管理'),
                      subtitle: Text('当前 ${controller.redeemRewards.length} 项'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: controller,
                            child: const ManageRedeemRewardsPage(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CSV 导入导出', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      const Text(
                        '会导出分类、内容、本轮反馈、薄弱点、改进措施、奖励兑换项、学习记录和兑换记录等 CSV 文件，'
                        '并支持追加导入或覆盖导入。',
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: controller.isBusy ? null : () => _exportAll(context, controller),
                        icon: const Icon(Icons.ios_share_outlined),
                        label: const Text('导出全部数据'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: controller.isBusy ? null : () => _importCsv(context, controller),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('从 CSV 导入'),
                      ),
                    ],
                  ),
                ),
              ),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportAll(
    BuildContext context,
    SettingsController controller,
  ) async {
    try {
      final result = await controller.exportAllData();
      if (!context.mounted) {
        return;
      }
      await NativeShareService.shareFiles(
        result.files.map((file) => file.path).toList(growable: false),
        text: '学习记录数据导出',
        subject: '学习记录 CSV 导出',
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出成功，文件目录：${result.directory.path}')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _importCsv(
    BuildContext context,
    SettingsController controller,
  ) async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (picked == null || picked.files.isEmpty || !context.mounted) {
      return;
    }

    final mode = await showDialog<CsvImportMode>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择导入方式'),
          content: const Text('追加导入会保留现有数据；覆盖导入只会覆盖本次选中的 CSV 类型。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(CsvImportMode.append),
              child: const Text('追加导入'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(CsvImportMode.overwrite),
              child: const Text('覆盖导入'),
            ),
          ],
        );
      },
    );

    if (mode == null) {
      return;
    }

    try {
      final paths =
          picked.files.map((item) => item.path).whereType<String>().toList(growable: false);
      final summary = await controller.importCsvFiles(paths, mode);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '导入成功：分类 ${summary.categories}，内容 ${summary.contentOptions}，'
            '本轮反馈 ${summary.rewardOptions}，记录 ${summary.studyRecords}',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('FormatException: ', ''))),
      );
    }
  }
}
