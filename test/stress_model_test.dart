import 'package:campus_twin/services/stress_model.dart';
import 'package:campus_twin/services/stress_predictor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await StressModel.instance.load();
  });

  test('model asset loads and predicts 3-class probabilities', () {
    expect(StressModel.instance.isLoaded, isTrue);
    final probs = StressModel.instance.predictProba(
      sleepHours: 7.0,
      exerciseMinutes: 60,
      screenTimeHours: 2.0,
    );
    expect(probs, hasLength(3));
    final sum = probs.reduce((a, b) => a + b);
    expect(sum, closeTo(1.0, 1e-6));
    for (final p in probs) {
      expect(p, greaterThanOrEqualTo(0));
      expect(p, lessThanOrEqualTo(1));
    }
  });

  test('healthy habits are predicted low stress', () {
    final probs = StressModel.instance.predictProba(
      sleepHours: 7.5,
      exerciseMinutes: 60,
      screenTimeHours: 2.0,
    );
    expect(probs[StressModel.low], greaterThan(probs[StressModel.moderate]));
    expect(probs[StressModel.low], greaterThan(probs[StressModel.high]));
  });

  test('poor habits are predicted moderate/high stress', () {
    final probs = StressModel.instance.predictProba(
      sleepHours: 4.5,
      exerciseMinutes: 5,
      screenTimeHours: 9.0,
    );
    expect(probs[StressModel.high] + probs[StressModel.moderate], greaterThan(probs[StressModel.low]));
  });

  test('predictor blends model + heuristic into a stable 0-100 score', () {
    final healthy = StressPredictor.compute(
      habitScore: 90,
      sleepHours: 7.5,
      exerciseMinutes: 60,
      screenTimeHours: 2.0,
    );
    expect(healthy.probabilities, hasLength(3));
    expect(healthy.score, inInclusiveRange(0, 100));
    expect(healthy.level, isA<String>());

    final poor = StressPredictor.compute(
      habitScore: 25,
      sleepHours: 4.5,
      exerciseMinutes: 5,
      screenTimeHours: 9.0,
    );
    expect(poor.level, isNot(''));
    expect(poor.featuresUsed['sleep_hours'], 4.5);

    expect(poor.score, greaterThan(healthy.score));
  });

  test('levelFor buckets match existing app thresholds', () {
    expect(StressPredictor.levelFor(20), 'low');
    expect(StressPredictor.levelFor(40), 'moderate');
    expect(StressPredictor.levelFor(70), 'moderate');
    expect(StressPredictor.levelFor(71), 'high');
  });
}