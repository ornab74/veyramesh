// SPDX-License-Identifier: GPL-3.0-only

final class PulseBatch {
  const PulseBatch({
    required this.steps,
    required this.stepSeconds,
    required this.interpolation,
    required this.droppedSeconds,
  });

  final int steps;
  final double stepSeconds;
  final double interpolation;
  final double droppedSeconds;
}

final class PulseClock {
  PulseClock({
    this.frequency = 60,
    this.maximumSteps = 8,
    this.maximumFrameSeconds = 0.25,
  }) : assert(frequency > 0),
       assert(maximumSteps > 0),
       assert(maximumFrameSeconds > 0);

  final double frequency;
  final int maximumSteps;
  final double maximumFrameSeconds;
  double _accumulator = 0;

  double get stepSeconds => 1 / frequency;

  PulseBatch advance(double elapsedSeconds) {
    final double accepted = elapsedSeconds.clamp(0, maximumFrameSeconds).toDouble();
    final double frameDrop = elapsedSeconds > maximumFrameSeconds
        ? elapsedSeconds - maximumFrameSeconds
        : 0;
    _accumulator += accepted;
    int steps = 0;
    while (_accumulator >= stepSeconds && steps < maximumSteps) {
      _accumulator -= stepSeconds;
      steps += 1;
    }
    double overloadDrop = 0;
    if (_accumulator >= stepSeconds) {
      overloadDrop = _accumulator - (_accumulator % stepSeconds);
      _accumulator %= stepSeconds;
    }
    return PulseBatch(
      steps: steps,
      stepSeconds: stepSeconds,
      interpolation: (_accumulator / stepSeconds).clamp(0, 1).toDouble(),
      droppedSeconds: frameDrop + overloadDrop,
    );
  }

  void reset() => _accumulator = 0;
}
