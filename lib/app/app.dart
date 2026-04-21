import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/add_record/pages/record_entry_page_runtime.dart';
import '../features/records/pages/records_overview_page.dart';
import '../features/rewards/pages/rewards_center_page.dart';
import '../features/settings/pages/settings_home_page_runtime.dart';
import 'app_services.dart';

class StudyPomodoroApp extends StatelessWidget {
  const StudyPomodoroApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppServices>.value(value: services),
        ChangeNotifierProvider<DataSyncNotifier>.value(value: services.dataSyncNotifier),
        ChangeNotifierProvider<ThemeController>.value(value: services.themeController),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            title: 'Memo',
            debugShowCheckedModeBanner: false,
            locale: const Locale('zh', 'CN'),
            supportedLocales: const [
              Locale('zh', 'CN'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.lightTheme(paletteKey: themeController.paletteKey),
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  static const double _kSwipeVelocityThreshold = 350;
  int _moduleDirection = 1;

  static const _titles = ['新增记录', '总记录', '积分奖励'];
  static const _pages = [
    AddRecordPage(),
    RecordsPage(),
    RewardsCenterPage(),
  ];

  void _switchToIndex(int index) {
    if (index < 0 || index >= _pages.length || index == _currentIndex) {
      return;
    }
    setState(() {
      _moduleDirection = index > _currentIndex ? 1 : -1;
      _currentIndex = index;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < _kSwipeVelocityThreshold) {
      return;
    }
    final isForward = velocity > 0;
    if (_trySwitchRecordMode(isForward)) {
      return;
    }
    _switchToIndex(isForward ? _currentIndex + 1 : _currentIndex - 1);
  }

  bool _trySwitchRecordMode(bool isForward) {
    if (_currentIndex != 0 && _currentIndex != 1) {
      return false;
    }
    if (isForward && RecordSharedModeMemory.mode == RecordSharedMode.study) {
      RecordSharedModeMemory.setMode(RecordSharedMode.life);
      return true;
    }
    if (!isForward && RecordSharedModeMemory.mode == RecordSharedMode.life) {
      RecordSharedModeMemory.setMode(RecordSharedMode.study);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            tooltip: '设置',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsHomePage(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) {
            final begin = Offset(_moduleDirection * 0.18, 0);
            final offsetAnimation = Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).animate(animation);
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_currentIndex),
            child: _pages[_currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          _switchToIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: '新增记录',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '总记录',
          ),
          NavigationDestination(
            icon: Icon(Icons.redeem_outlined),
            selectedIcon: Icon(Icons.redeem),
            label: '积分奖励',
          ),
        ],
      ),
    );
  }
}
