import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/settings_controller_runtime.dart';
import 'manage_break_items_page_runtime.dart';

class ManageFeedbackPage extends StatelessWidget {
  const ManageFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('休息管理')),
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
                      leading: const Icon(Icons.free_breakfast_outlined),
                      title: const Text('短休息管理'),
                      subtitle: Text('当前 ${controller.shortBreakOptions.length} 项'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: controller,
                              child: const ManageBreakItemsPage(type: 'short'),
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.weekend_outlined),
                      title: const Text('长休息管理'),
                      subtitle: Text('当前 ${controller.longBreakOptions.length} 项'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: controller,
                              child: const ManageBreakItemsPage(type: 'long'),
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.tune_outlined),
                      title: const Text('长休息触发阈值'),
                      subtitle: Text('每完成 ${controller.longBreakEvery} 个番茄后进入一次长休息'),
                      trailing: DropdownButton<int>(
                        value: controller.longBreakEvery,
                        underline: const SizedBox.shrink(),
                        items: const [2, 3, 4]
                            .map(
                              (value) => DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value'),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: controller.isBusy
                            ? null
                            : (value) {
                                if (value != null) {
                                  controller.setLongBreakEveryValue(value);
                                }
                              },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.timelapse_outlined),
                      title: const Text('学习 Session 间隔'),
                      subtitle: Text(
                        '相邻两条记录超过 ${controller.sessionGapMinutes} 分钟后，视为新的学习 session',
                      ),
                      trailing: DropdownButton<int>(
                        value: controller.sessionGapMinutes,
                        underline: const SizedBox.shrink(),
                        items: const [30, 60, 90, 120]
                            .map(
                              (value) => DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value 分钟'),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: controller.isBusy
                            ? null
                            : (value) {
                                if (value != null) {
                                  controller.setSessionGapMinutesValue(value);
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
