// SPDX-License-Identifier: GPL-3.0-only

import 'chronicle.dart';
import 'hypothesis.dart';
import 'protocol.dart';
import 'pulse_clock.dart';
import 'study_space.dart';

final class StudyRunner {
  StudyRunner({
    required this.name,
    required this.space,
    PulseClock? clock,
  })  : clock = clock ?? PulseClock(),
        chronicle = Chronicle(studyName: name, seed: space.seed);

  final String name;
  final StudySpace space;
  final PulseClock clock;
  final Chronicle chronicle;
  final ProtocolGraph protocols = ProtocolGraph();
  final List<Hypothesis> hypotheses = <Hypothesis>[];
  int pulse = 0;
  double wallSeconds = 0;
  double interpolation = 0;
  double droppedSeconds = 0;
  bool paused = false;

  void addProtocol(Protocol protocol) => protocols.add(protocol);
  void addHypothesis(Hypothesis hypothesis) => hypotheses.add(hypothesis);

  int advance(double elapsedSeconds) {
    wallSeconds += elapsedSeconds;
    if (paused) return 0;
    final PulseBatch batch = clock.advance(elapsedSeconds);
    interpolation = batch.interpolation;
    droppedSeconds += batch.droppedSeconds;
    for (int i = 0; i < batch.steps; i += 1) {
      _runPulse(batch.stepSeconds);
    }
    _runPresentation(elapsedSeconds);
    return batch.steps;
  }

  void _runPulse(double deltaSeconds) {
    pulse += 1;
    final Map<String, int> durations = <String, int>{};
    for (final Protocol protocol in protocols.ordered()) {
      if (!protocol.enabled || protocol.phase == ProtocolPhase.presentation) continue;
      final Stopwatch watch = Stopwatch()..start();
      protocol.run(ProtocolContext(
        space: space,
        chronicle: chronicle,
        pulse: pulse,
        deltaSeconds: deltaSeconds,
        interpolation: interpolation,
        phase: protocol.phase,
      ));
      watch.stop();
      durations[protocol.name] = watch.elapsedMicroseconds;
    }
    final int edits = space.commit();
    chronicle.pulses.add(PulseRecord(
      index: pulse,
      deltaSeconds: deltaSeconds,
      wallSeconds: wallSeconds,
      committedEdits: edits,
      protocolDurationsMicros: durations,
    ));
  }

  void _runPresentation(double deltaSeconds) {
    for (final Protocol protocol in protocols.ordered()) {
      if (!protocol.enabled || protocol.phase != ProtocolPhase.presentation) continue;
      protocol.run(ProtocolContext(
        space: space,
        chronicle: chronicle,
        pulse: pulse,
        deltaSeconds: deltaSeconds,
        interpolation: interpolation,
        phase: protocol.phase,
      ));
    }
  }

  List<HypothesisResult> evaluateHypotheses() => <HypothesisResult>[
        for (final Hypothesis hypothesis in hypotheses)
          hypothesis.evaluate(space, chronicle),
      ];
}
