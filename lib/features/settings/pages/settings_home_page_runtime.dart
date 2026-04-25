import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../app/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/csv_service_runtime.dart';
import '../controllers/settings_controller_runtime.dart';
import 'manage_categories_page_runtime.dart';
import 'manage_contents_page_runtime.dart';
import 'manage_feedback_page_runtime.dart';
import 'manage_improvement_options_hub_page_runtime.dart';
import 'manage_life_options_page_runtime.dart';
import 'manage_redeem_rewards_page_runtime.dart';
import 'manage_weakness_options_hub_page_runtime.dart';

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
                    Consumer<ThemeController>(
                      builder: (context, themeController, child) {
                        return ListTile(
                          leading: const Icon(Icons.palette_outlined),
                          title: const Text('主题配色'),
                          subtitle: Text(
                            AppTheme.palettes[themeController.paletteKey]
                                    ?.name ??
                                '默认',
                          ),
                          trailing: DropdownButton<String>(
                            value: themeController.paletteKey,
                            underline: const SizedBox.shrink(),
                            items: AppTheme.palettes.entries
                                .map(
                                  (entry) => DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(entry.value.name),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              if (value != null) {
                                themeController.setPalette(value);
                              }
                            },
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: false,
                        leading: const Icon(Icons.folder_open_outlined),
                        title: const Text('内容管理'),
                        subtitle: const Text('学习 / 生活'),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        children: [
                          _buildTile(
                            context,
                            icon: Icons.school_outlined,
                            title: '学习',
                            subtitle:
                                '分类 ${controller.categories.length} · 内容 ${controller.contentOptions.length}',
                            page: ChangeNotifierProvider.value(
                              value: controller,
                              child: const _StudyContentManagementPage(),
                            ),
                          ),
                          _buildTile(
                            context,
                            icon: Icons.self_improvement_outlined,
                            title: '生活',
                            subtitle: '记录项 ${controller.lifeOptions.length}',
                            page: ChangeNotifierProvider.value(
                              value: controller,
                              child: const ManageLifeOptionsPage(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    _buildTile(
                      context,
                      icon: Icons.redeem_outlined,
                      title: '奖励兑换管理',
                      subtitle: '当前 ${controller.redeemRewards.length} 项',
                      page: ChangeNotifierProvider.value(
                        value: controller,
                        child: const ManageRedeemRewardsPage(),
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
                      Text('数据备份与恢复',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      const Text(
                        '导出为单文件备份。首次选择备份文件夹后，后续新增和修改会自动备份到该目录。',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        controller.backupDirectoryPath == null
                            ? '当前未设置自动备份文件夹'
                            : '自动备份目录：${controller.backupDirectoryPath}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.transferDirectoryPath == null
                            ? '当前未设置导入导出文件夹'
                            : '导入导出目录：${controller.transferDirectoryPath}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: controller.isBusy
                            ? null
                            : () => _exportAll(context, controller),
                        icon: const Icon(Icons.ios_share_outlined),
                        label: const Text('导出数据'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: controller.isBusy
                            ? null
                            : () => _pickBackupDirectory(context, controller),
                        icon: const Icon(Icons.folder_open_outlined),
                        label: const Text('更换备份文件夹'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: controller.isBusy
                            ? null
                            : () => _importCsv(context, controller),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('导入备份文件'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      ),
    );
  }

  Future<void> _exportAll(
    BuildContext context,
    SettingsController controller,
  ) async {
    final allowed = await _ensureStoragePermission(context);
    if (!allowed) {
      return;
    }
    try {
      final result = await controller.exportManualDataToTransferDirectory();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出成功：${result.primaryFile.path}')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_formatError(error))),
      );
    }
  }

  Future<void> _importCsv(
    BuildContext context,
    SettingsController controller,
  ) async {
    late final String directoryPath;
    try {
      directoryPath = controller.requireTransferDirectoryPath();
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['json', 'csv'],
      initialDirectory: directoryPath,
    );
    if (picked == null || picked.files.isEmpty || !context.mounted) {
      return;
    }

    final mode = await showDialog<CsvImportMode>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择导入方式'),
          content: const Text('追加导入会保留现有数据；覆盖导入会覆盖本次导入中包含的数据类型。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(CsvImportMode.append),
              child: const Text('追加导入'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(CsvImportMode.overwrite),
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
      final paths = picked.files
          .map((item) => item.path)
          .whereType<String>()
          .toList(growable: false);
      final summary = await controller.importCsvFiles(paths, mode);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '导入成功：分类 ${summary.categories}，内容 ${summary.contentOptions}，休息项 ${summary.feedbackOptions}，'
            '薄弱点 ${summary.weaknessOptions}，改进措施 ${summary.improvementOptions}，奖励 ${summary.redeemRewards}，'
            '记录 ${summary.studyRecords}，兑换记录 ${summary.rewardRedemptionRecords}',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_formatError(error))),
      );
    }
  }

  Future<void> _pickBackupDirectory(
    BuildContext context,
    SettingsController controller,
  ) async {
    final allowed = await _ensureStoragePermission(context);
    if (!allowed) {
      return;
    }
    final picked = await FilePicker.platform.getDirectoryPath(
      initialDirectory: controller.backupDirectoryPath ??
          controller.lastTransferDirectoryPath,
    );
    if (picked == null || picked.trim().isEmpty) {
      return;
    }
    try {
      final result = await controller.exportAllDataToDirectory(picked);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('备份文件夹已更新：${result.directory.path}')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_formatError(error))),
      );
    }
  }

  String _formatError(Object error) {
    final text = error.toString();
    return text
        .replaceFirst('Bad state: ', '')
        .replaceFirst('FileSystemException: ', '')
        .replaceFirst('FormatException: ', '');
  }

  Future<bool> _ensureStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true;
    }

    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) {
      return true;
    }

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    final shouldOpenSettings = manageStatus.isPermanentlyDenied ||
        storageStatus.isPermanentlyDenied ||
        manageStatus.isRestricted ||
        storageStatus.isRestricted;
    if (shouldOpenSettings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请在系统设置中允许“文件和媒体”权限后再试。')),
      );
      await openAppSettings();
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('未授予存储权限，无法导出或设置备份目录。')),
    );
    return false;
  }
}

class _StudyContentManagementPage extends StatelessWidget {
  const _StudyContentManagementPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        Widget navTile({
          required IconData icon,
          required String title,
          required String subtitle,
          required Widget page,
        }) {
          return ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => page),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('学习内容管理')),
          body: ListView(
            children: [
              navTile(
                icon: Icons.category_outlined,
                title: '分类管理',
                subtitle: '当前 ${controller.categories.length} 项',
                page: ChangeNotifierProvider.value(
                  value: controller,
                  child: const ManageCategoriesPage(),
                ),
              ),
              const Divider(height: 1),
              navTile(
                icon: Icons.book_outlined,
                title: '内容管理',
                subtitle: '当前 ${controller.contentOptions.length} 项',
                page: ChangeNotifierProvider.value(
                  value: controller,
                  child: const ManageContentsPage(),
                ),
              ),
              const Divider(height: 1),
              navTile(
                icon: Icons.hotel_outlined,
                title: '休息管理',
                subtitle:
                    '短休息 ${controller.shortBreakOptions.length} 项 · 长休息 ${controller.longBreakOptions.length} 项',
                page: ChangeNotifierProvider.value(
                  value: controller,
                  child: const ManageFeedbackPage(),
                ),
              ),
              const Divider(height: 1),
              navTile(
                icon: Icons.report_problem_outlined,
                title: '薄弱点管理',
                subtitle: '当前 ${controller.weaknessOptions.length} 项',
                page: ChangeNotifierProvider.value(
                  value: controller,
                  child: const ManageWeaknessOptionsHubPage(),
                ),
              ),
              const Divider(height: 1),
              navTile(
                icon: Icons.build_circle_outlined,
                title: '改进措施管理',
                subtitle: '当前 ${controller.improvementOptions.length} 项',
                page: ChangeNotifierProvider.value(
                  value: controller,
                  child: const ManageImprovementOptionsHubPage(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
