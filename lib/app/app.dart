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
  int _swipePosition = 0;
  static const double _kSwipeVelocityThreshold = 350;
  int _moduleDirection = 1;

  static const _titles = ['新增记录', '总记录', '积分奖励'];
  static const _pages = [
    AddRecordPage(),
    RecordsPage(),
    RewardsCenterPage(),
  ];

  int _positionForIndex(int index) {
    if (index == 0) {
      return RecordSharedModeMemory.mode == RecordSharedMode.life ? 1 : 0;
    }
    if (index == 1) {
      return RecordSharedModeMemory.mode == RecordSharedMode.life ? 3 : 2;
    }
    return 4;
  }

  void _applySwipePosition(int nextPosition) {
    if (nextPosition == _swipePosition) {
      return;
    }
    final bounded = nextPosition.clamp(0, 4);
    final previousIndex = _currentIndex;
    int nextIndex;
    if (bounded <= 1) {
      nextIndex = 0;
      RecordSharedModeMemory.setMode(
        bounded == 0 ? RecordSharedMode.study : RecordSharedMode.life,
      );
    } else if (bounded <= 3) {
      nextIndex = 1;
      RecordSharedModeMemory.setMode(
        bounded == 2 ? RecordSharedMode.study : RecordSharedMode.life,
      );
    } else {
      nextIndex = 2;
    }

    setState(() {
      _swipePosition = bounded;
      _moduleDirection = nextIndex > previousIndex ? 1 : -1;
      _currentIndex = nextIndex;
    });
  }

  void _switchToIndex(int index) {
    if (index < 0 || index >= _pages.length || index == _currentIndex) {
      return;
    }
    setState(() {
      _moduleDirection = index > _currentIndex ? 1 : -1;
      _currentIndex = index;
      _swipePosition = _positionForIndex(index);
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < _kSwipeVelocityThreshold) {
      return;
    }
    final isForward = velocity < 0;
    _applySwipePosition(_swipePosition + (isForward ? 1 : -1));
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
        child: ClipRect(
          child: TweenAnimationBuilder<Offset>(
            key: ValueKey<int>(_currentIndex),
            tween: Tween<Offset>(
              begin: Offset(_moduleDirection * 0.09, 0),
              end: Offset.zero,
            ),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: _pages[_currentIndex],
            builder: (context, offset, child) {
              return FractionalTranslation(
                translation: offset,
                child: child,
              );
            },
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
