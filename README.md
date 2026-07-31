# VeyraMesh Observatory

**Research and education platform for deterministic simulation experiments.**

VeyraMesh Observatory. It is a laboratory for asking questions about simulation architectures.

- How do alternative storage layouts affect iteration cost?
- How does fixed-step scheduling change repeatability?
- Which protocol dependency graphs are stable under reordering?
- How can a run be replayed, compared, and falsified?
- How can software behavior be discussed without redistributing another project's expression?

The project uses its own research vocabulary and execution model:

| VeyraMesh concept | Meaning |
|---|---|
| **Specimen** | A generational handle representing one observed subject |
| **Measure** | A typed column of recorded or simulated state |
| **Cohort** | A cached selection of specimens satisfying a research lens |
| **Protocol** | A named experimental operation with declared dependencies |
| **Pulse** | One deterministic advancement of the study |
| **Chronicle** | Append-only observations and reproducibility metadata |
| **Transaction** | Deferred changes committed at a pulse boundary |
| **Hypothesis** | An executable assertion evaluated against observations |


## Workspace

```text
packages/veyra_lab/          Pure Dart experiment runtime
apps/veyra_observatory/      Flutter visualization and teaching console
docs/                        Architecture and clean-room policy
references/                  Optional, quarantined research references
tool/                        Verification and full-run scripts
```

## Full run

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
(cd packages/veyra_lab && dart test)
(cd apps/veyra_observatory && flutter test)
(cd apps/veyra_observatory && flutter build web --release)
dart run tool/verify_transformative_use.dart
```

Or:

```bash
./tool/full_run.sh
```

## Minimal study

```dart
final StudySpace space = StudySpace(seed: 42);
final Measure<Vec2> position = Measure<Vec2>('position');
final Measure<Vec2> velocity = Measure<Vec2>('velocity');

space.registerMeasures(<Measure<Object>>[
  position.erased,
  velocity.erased,
]);

space.transaction.spawn(<Measurement<Object>>[
  position(Vec2.zero).erased,
  velocity(const Vec2(10, 0)).erased,
]);
space.commit();

final Cohort moving = space.cohort(
  CohortLens.all(<Measure<Object>>[position.erased, velocity.erased]),
);

final Protocol drift = Protocol(
  name: 'drift-observation',
  phase: ProtocolPhase.intervention,
  run: (ProtocolContext context) {
    for (final Specimen specimen in moving.members) {
      final Vec2 p = space.require(specimen, position);
      final Vec2 v = space.require(specimen, velocity);
      space.write(specimen, position, p + v * context.deltaSeconds);
    }
  },
);
```

## License

VeyraMesh code is GPL-3.0-only

## Status

VeyraMesh is an experimental research platform. Its APIs prioritize explicitness, reproducibility, inspectability, and educational value over compatibility with any existing engine.
