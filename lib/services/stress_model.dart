import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

// =============================================================================
// ON-DEVICE STRESS MODEL — Random Forest (scikit-learn) exported as data.
//
// Trained by ml/train_stress_model.py on the Kaggle "Human Stress Detection -
// Extended" dataset (shijo96john), using only the features shared with the
// CampusTwin HabitLog collection:
//    feature[0] = sleep_duration  (hours, from sleep_hours)
//    feature[1] = physical_activity (exercise_minutes / 30, dataset scale)
//    feature[2] = screen_time     (hours, from screen_time_hours)
//
// The input is scaled with the RobustScaler constants stored in the model
// asset, then pushed through every decision tree in the ensemble. This class
// is a tiny tree interpreter — the weights/thresholds live in
// assets/stress_model.json, so nothing heavy is compiled into the binary.
//
// Class index: 0 = low, 1 = moderate, 2 = high stress.
// =============================================================================

class StressModel {
  StressModel._();
  static final StressModel instance = StressModel._();

  static const String asset = 'assets/stress_model.json';
  static const int classCount = 3;

  // Predicted class indices (also array positions for probabilities).
  static const int low = 0;
  static const int moderate = 1;
  static const int high = 2;

  /// Exercise minutes → dataset "physical activity" scale (30 min ≈ 1 unit).
  static const double physicalActivityMinutesPerUnit = 30.0;

  List<double>? _median;
  List<double>? _iqr;
  List<_Tree>? _trees;

  /// Loads (once) the model asset. Safe to call repeatedly.
  Future<void> load() async {
    if (_trees != null) return;
    final raw = await rootBundle.loadString(asset);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _median = (data['median'] as List).cast<double>();
    _iqr = (data['iqr'] as List).cast<double>();
    _trees = [
      for (final t in data['trees'] as List)
        _Tree(
          left: (t[0] as List).cast<int>(),
          right: (t[1] as List).cast<int>(),
          feature: (t[2] as List).cast<int>(),
          threshold: (t[3] as List).cast<double>(),
          values: (t[4] as List).cast<double>(),
        ),
    ];
  }

  bool get isLoaded => _trees != null;

  /// Predicts [low, moderate, high] probabilities from the raw in-app habit
  /// values. Must call [load] first.
  List<double> predictProba({
    required double sleepHours,
    required double exerciseMinutes,
    required double screenTimeHours,
  }) {
    final trees = _trees;
    if (trees == null) {
      throw StateError('StressModel not loaded. Call load() first.');
    }
    final raw = [
      sleepHours,
      exerciseMinutes / physicalActivityMinutesPerUnit,
      screenTimeHours,
    ];
    final scaled = List<double>.filled(raw.length, 0);
    for (var i = 0; i < raw.length; i++) {
      scaled[i] = (raw[i] - _median![i]) / _iqr![i];
    }

    final probs = List<double>.filled(classCount, 0);
    for (final t in trees) {
      var node = 0;
      while (t.left[node] != -1) {
        node = scaled[t.feature[node]] <= t.threshold[node]
            ? t.left[node]
            : t.right[node];
      }
      final base = node * classCount;
      for (var c = 0; c < classCount; c++) {
        probs[c] += t.values[base + c];
      }
    }
    final denom = probs.reduce((a, b) => a + b);
    if (denom <= 0) return List.filled(classCount, 1 / classCount);
    return [for (final p in probs) p / denom];
  }

  /// Predicted class index (0 = low, 1 = moderate, 2 = high).
  int predictClass({
    required double sleepHours,
    required double exerciseMinutes,
    required double screenTimeHours,
  }) {
    final p = predictProba(
      sleepHours: sleepHours,
      exerciseMinutes: exerciseMinutes,
      screenTimeHours: screenTimeHours,
    );
    var best = 0;
    for (var c = 1; c < p.length; c++) {
      if (p[c] > p[best]) best = c;
    }
    return best;
  }
}

/// One decision tree — node arrays in sklearn's layout. A node is a leaf when
/// `left[node] == -1`. Leaf class distributions live in `values` (flat,
/// stride [StressModel.classCount]).
class _Tree {
  const _Tree({
    required this.left,
    required this.right,
    required this.feature,
    required this.threshold,
    required this.values,
  });

  final List<int> left;
  final List<int> right;
  final List<int> feature;
  final List<double> threshold;
  final List<double> values;
}