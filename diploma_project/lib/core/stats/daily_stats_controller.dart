import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyStatsController extends ChangeNotifier {
  static const _keyDate = 'stats_date';
  static const _keyWater = 'stats_water';
  static const _keyCalories = 'stats_calories';
  static const _keySteps = 'stats_steps';
  static const _keyStepBase = 'stats_step_base';

  static const int waterTarget = 8;
  static const int caloriesTarget = 2000;
  static const int stepsTarget = 10000;

  int _water = 0;
  int _calories = 0;
  int _steps = 0;
  int _stepBase = -1; // cumulative from sensor at start of day; -1 = unknown

  bool _pedometerActive = false;
  StreamSubscription<StepCount>? _stepSub;

  int get water => _water;
  int get calories => _calories;
  int get steps => _steps;
  bool get pedometerActive => _pedometerActive;

  DailyStatsController() {
    _load();
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(_keyDate) ?? '';
    if (saved != _todayKey()) {
      _water = 0;
      _calories = 0;
      _steps = 0;
      _stepBase = -1;
      await _persist(p);
    } else {
      _water = p.getInt(_keyWater) ?? 0;
      _calories = p.getInt(_keyCalories) ?? 0;
      _steps = p.getInt(_keySteps) ?? 0;
      _stepBase = p.getInt(_keyStepBase) ?? -1;
    }
    notifyListeners();
    _initPedometer();
  }

  void _initPedometer() {
    _stepSub?.cancel();
    try {
      _stepSub = Pedometer.stepCountStream.listen(
        (event) {
          final total = event.steps;
          if (_stepBase < 0) {
            // First sensor reading today — set baseline so today starts at current step count
            _stepBase = total - _steps;
            _saveStepBase(_stepBase);
          }
          final todaySteps = (total - _stepBase).clamp(0, 99999);
          if (todaySteps != _steps) {
            _steps = todaySteps;
            notifyListeners();
            _persist();
          }
          if (!_pedometerActive) {
            _pedometerActive = true;
            notifyListeners();
          }
        },
        onError: (_) {
          _pedometerActive = false;
          notifyListeners();
        },
      );
    } catch (_) {
      _pedometerActive = false;
    }
  }

  Future<void> _saveStepBase(int base) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyStepBase, base);
  }

  Future<void> _persist([SharedPreferences? p]) async {
    p ??= await SharedPreferences.getInstance();
    await p.setString(_keyDate, _todayKey());
    await p.setInt(_keyWater, _water);
    await p.setInt(_keyCalories, _calories);
    await p.setInt(_keySteps, _steps);
    if (_stepBase >= 0) await p.setInt(_keyStepBase, _stepBase);
  }

  Future<void> addWater() async {
    if (_water >= 20) return;
    _water++;
    notifyListeners();
    await _persist();
  }

  Future<void> removeWater() async {
    if (_water <= 0) return;
    _water--;
    notifyListeners();
    await _persist();
  }

  Future<void> addCalories(int kcal) async {
    _calories = (_calories + kcal).clamp(0, 9999);
    notifyListeners();
    await _persist();
  }

  Future<void> resetCalories() async {
    _calories = 0;
    notifyListeners();
    await _persist();
  }

  // Used only when pedometer is not active
  Future<void> setSteps(int value) async {
    if (_pedometerActive) return;
    _steps = value.clamp(0, 99999);
    notifyListeners();
    await _persist();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    super.dispose();
  }
}
