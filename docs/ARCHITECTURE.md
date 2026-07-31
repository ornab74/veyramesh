# Architecture

VeyraMesh models a scientific study rather than a game world.

## Data plane

`StudySpace` owns generational `Specimen` handles and typed `Measure<T>` columns. Each measure is stored densely with sparse index lookup. Structural revisions invalidate only cohorts whose required or excluded measures changed.

## Selection plane

A `CohortLens` declares required and excluded measures plus an optional predicate. `Cohort` caches membership and refreshes when the study's structural revision changes.

## Execution plane

`Protocol` instances form a dependency graph inside named phases:

1. preparation
2. intervention
3. observation
4. analysis
5. presentation

`ProtocolGraph` performs stable topological ordering. Cycles and missing dependencies are configuration errors.

## Temporal plane

`PulseClock` converts irregular wall time into deterministic fixed pulses. It clamps extreme deltas, limits catch-up work, and exposes interpolation for presentation.

## Integrity plane

A `StudyTransaction` defers births, retirements, and measurement edits until the current protocol boundary. `Chronicle` records pulse metadata, observations, hypothesis results, and hashes used for replay comparison.

## Research plane

`Hypothesis` functions evaluate observations without modifying the study. `ComparativeRun` aligns chronicles by pulse and emits deltas rather than attempting source-level equivalence.
