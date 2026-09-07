import 'package:campus_twin/services/stress_model.dart';

// =============================================================================
// STRESS PREDICTOR
//
// Blends the on-device Random Forest (3 features shared with the habit DB) with
// the existing goal-aware habit score so the final 0–100 stress score is stable
// and explainable:
//   modelScore       = probs · [20, 55, 90]  (low, moderate, high severity)
//   heuristicScore   = 100 − habitScore
//   final score      = 0.5·modelScore + 0.5·heuristicScore
// =============================================================================

class StressPredictionResult {
  const StressPredictionResult({
    required this.modelClass,
    required this.probabilities,
    required this.modelScore,
    required this.heuristicScore,
    required this.score,
    required this.level,
    required this.featuresUsed,
  });

  /// 0 = low, 1 = moderate, 2 = high (argmax of the forest).
  final int modelClass;

  /// On-device model [low, moderate, high] probabilities.
  final List<double> probabilities;

  /// 0–100 severity derived purely from the model's probabilities.
  final double modelScore;

  /// 100 − habit score (existing goal-aware heuristic).
  final double heuristicScore;

  /// Blended 0–100 stress score.
  final int score;

  /// 'low' | 'moderate' | 'high' derived from [score].
  final String level;

  /// The raw habit values the model consumed (for transparency/diagnostics).
  final Map<String, double> featuresUsed;

  double get probabilityLow => probabilities[0];
  double get probabilityModerate => probabilities[1];
  double get probabilityHigh => probabilities[2];
}

class StressPredictor {
  StressPredictor._();

  /// Severity anchors for the three classes (smoothed scores, not exact).
  static const List<double> severity = [20, 55, 90];

  /// How much the ML model weighs vs the goal-aware heuristic.
  static const double modelWeight = 0.5;

  static String levelFor(int score) {
    if (score < 40) return 'low';
    if (score <= 70) return 'moderate';
    return 'high';
  }

  /// Runs the on-device Random Forest over the habit values. The model must be
  /// loaded (StressModel.instance.load()) before calling this.
  static StressPredictionResult compute({
    required double habitScore,
    required double sleepHours,
    required double exerciseMinutes,
    required double screenTimeHours,
  }) {
    final probs = StressModel.instance.predictProba(
      sleepHours: sleepHours,
      exerciseMinutes: exerciseMinutes,
      screenTimeHours: screenTimeHours,
    );

    var modelScore = 0.0;
    for (var c = 0; c < probs.length; c++) {
      modelScore += probs[c] * severity[c];
    }

    final heuristicScore = (100 - habitScore).clamp(0.0, 100.0);
    final score = (modelWeight * modelScore + (1 - modelWeight) * heuristicScore)
        .round()
        .clamp(0, 100);

    var modelClass = 0;
    for (var c = 1; c < probs.length; c++) {
      if (probs[c] > probs[modelClass]) modelClass = c;
    }

    return StressPredictionResult(
      modelClass: modelClass,
      probabilities: probs,
      modelScore: modelScore,
      heuristicScore: heuristicScore,
      score: score,
      level: levelFor(score),
      featuresUsed: {
        'sleep_hours': sleepHours,
        'exercise_minutes': exerciseMinutes,
        'screen_time_hours': screenTimeHours,
      },
    );
  }
}