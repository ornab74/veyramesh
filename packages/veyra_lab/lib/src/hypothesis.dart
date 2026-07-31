// SPDX-License-Identifier: GPL-3.0-only

import 'chronicle.dart';
import 'study_space.dart';

final class HypothesisResult {
  const HypothesisResult({
    required this.name,
    required this.passed,
    required this.explanation,
    this.evidence = const <String, Object?>{},
  });

  final String name;
  final bool passed;
  final String explanation;
  final Map<String, Object?> evidence;
}

typedef HypothesisTest = HypothesisResult Function(
  StudySpace space,
  Chronicle chronicle,
);

final class Hypothesis {
  const Hypothesis({
    required this.name,
    required this.question,
    required this.evaluate,
  });

  final String name;
  final String question;
  final HypothesisTest evaluate;
}
