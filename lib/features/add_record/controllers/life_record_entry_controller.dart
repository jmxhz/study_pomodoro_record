import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../app/app_services.dart';
import '../../../data/models/life_option.dart';
import '../../../data/models/study_record.dart';
import '../../../data/repositories/options_repository.dart';
import '../../../data/repositories/study_record_repository.dart';

class LifeRecordEntryController extends ChangeNotifier {
  LifeRecordEntryController({
    required this.optionsRepository,
    required this.studyRecordRepository,
    required this.dataSyncNotifier,
  }) {
    _syncListener = () {
      load(preserveSelection: true);
    };
    dataSyncNotifier.addListener(_syncListener);
    _startClockTicker();
    load();
  }

  final OptionsRepository optionsRepository;
  final StudyRecordRepository studyRecordRepository;
  final DataSyncNotifier dataSyncNotifier;

  late final VoidCallback _syncListener;
  Timer? _clockTimer;

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;
  List<LifeOption> _lifeOptions = const [];

  LifeOption? selectedOption;
  DateTime occurredAt = DateTime.now();
  String? notes;
  bool _autoTrackCurrentTime = true;

  List<LifeOption> get lifeOptions => _visibleLifeOptions();

  bool get hasEnabledLifeOptions => _lifeOptions.any((item) => item.isEnabled);

  Future<void> load({bool preserveSelection = false}) async {
    try {
      if (!preserveSelection) {
        isLoading = true;
      }
      errorMessage = null;
      notifyListeners();

      _lifeOptions = await optionsRepository.getLifeOptions();
      if (!preserveSelection) {
        _applyDefaultSelection();
      } else {
        _reconcileSelection();
      }
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectLifeOption(LifeOption? value) {
    selectedOption = value;
    notifyListeners();
  }

  void setNotes(String value) {
    notes = value.trim().isEmpty ? null : value.trim();
    notifyListeners();
  }

  void setOccurredAt(DateTime value, {bool manual = true}) {
    occurredAt = value;
    if (manual) {
      _autoTrackCurrentTime = false;
    }
    notifyListeners();
  }

  String? validateForm() {
    if (selectedOption == null) {
      return '请选择生活记录项。';
    }
    return null;
  }

  Future<void> save() async {
    final validationMessage = validateForm();
    if (validationMessage != null) {
      throw StateError(validationMessage);
    }

    try {
      isSaving = true;
      notifyListeners();

      final now = DateTime.now();
      final option = selectedOption!;
      final dayStart =
          DateTime(occurredAt.year, occurredAt.month, occurredAt.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final sameDayRecords =
          await studyRecordRepository.getLifeRecordsBetween(dayStart, dayEnd);
      final selectedName = _normalizeName(option.name);
      final alreadyRecordedToday = sameDayRecords.any((record) {
        if (option.id != null && record.lifeOptionId != null) {
          return record.lifeOptionId == option.id;
        }
        if (record.lifeOptionId == null) {
          return _normalizeName(record.contentNameSnapshot) == selectedName;
        }
        return false;
      });
      if (alreadyRecordedToday) {
        throw StateError('该生活记录项今天已记录，不能重复记录。');
      }
      final record = StudyRecord(
        recordKind: 'life',
        lifeOptionId: option.id,
        occurredAt: occurredAt,
        categoryId: null,
        categoryNameSnapshot: '生活',
        contentOptionId: null,
        contentNameSnapshot: option.name,
        rewardOptionId: null,
        rewardNameSnapshot: '',
        feedbackOptionId: null,
        feedbackNameSnapshot: null,
        pomodoroCount: 1,
        points: option.points,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );
      await studyRecordRepository.insertRecord(record);
      dataSyncNotifier.notifyChanged();
      _resetForNext();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void _applyDefaultSelection() {
    selectedOption = _lifeOptions.where((item) => item.isEnabled).firstOrNull;
    _autoTrackCurrentTime = true;
    occurredAt = DateTime.now();
    notes = null;
  }

  void _resetForNext() {
    _autoTrackCurrentTime = true;
    occurredAt = DateTime.now();
    notes = null;
  }

  void _reconcileSelection() {
    if (selectedOption != null) {
      final matched = _lifeOptions.where((item) =>
          item.id == selectedOption!.id && item.name == selectedOption!.name);
      if (matched.isNotEmpty) {
        selectedOption = matched.first;
      }
    }
    final available = _visibleLifeOptions();
    if (selectedOption == null ||
        !available.any((item) =>
            item.id == selectedOption!.id &&
            item.name == selectedOption!.name)) {
      selectedOption = available.firstOrNull;
    }
    if (_autoTrackCurrentTime) {
      occurredAt = DateTime.now();
    }
  }

  List<LifeOption> _visibleLifeOptions() {
    final result =
        _lifeOptions.where((item) => item.isEnabled).toList(growable: true);
    final selected = selectedOption;
    if (selected != null &&
        !result.any(
            (item) => item.id == selected.id && item.name == selected.name)) {
      result.insert(0, selected);
    }
    return result;
  }

  void _startClockTicker() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!_autoTrackCurrentTime) {
        return;
      }
      final now = DateTime.now();
      if (!_sameMinute(occurredAt, now)) {
        occurredAt = now;
        notifyListeners();
      }
    });
  }

  bool _sameMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;

  String _normalizeName(String value) =>
      value.replaceAll(RegExp(r'\s+'), '').trim().toLowerCase();

  @override
  void dispose() {
    _clockTimer?.cancel();
    dataSyncNotifier.removeListener(_syncListener);
    super.dispose();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
