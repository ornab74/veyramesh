// SPDX-License-Identifier: GPL-3.0-only

import 'dart:math' as math;

import 'cohort.dart';
import 'measure.dart';
import 'specimen.dart';
import 'transaction.dart';

final class StudySpace {
  StudySpace({int seed = 1}) : random = math.Random(seed), seed = seed;

  final int seed;
  final math.Random random;
  final SpecimenRegistry _registry = SpecimenRegistry();
  final Map<Measure<Object>, MeasureColumnBase> _columns =
      <Measure<Object>, MeasureColumnBase>{};
  final Map<Object, Object> _instruments = <Object, Object>{};
  final StudyTransaction transaction = StudyTransaction();
  int _structuralRevision = 0;

  int get structuralRevision => _structuralRevision;
  int get specimenCount => _registry.activeCount;
  Iterable<Specimen> get specimens => _registry.active;
  Iterable<Measure<Object>> get registeredMeasures => _columns.keys;

  void registerMeasure<T extends Object>(Measure<T> measure) {
    _columns.putIfAbsent(measure.erased, () => MeasureColumn<T>(measure));
  }

  void registerMeasures(Iterable<Measure<Object>> measures) {
    for (final Measure<Object> measure in measures) registerMeasure<Object>(measure);
  }

  void installInstrument<T extends Object>(T instrument, {Object? key}) {
    _instruments[key ?? T] = instrument;
  }

  T instrument<T extends Object>({Object? key}) {
    final Object? value = _instruments[key ?? T];
    if (value is! T) throw StateError('No instrument $T is installed.');
    return value;
  }

  Specimen createNow([Iterable<Measurement<Object>> measurements = const []]) {
    final Specimen specimen = _registry.create();
    for (final Measurement<Object> measurement in measurements) {
      writeErased(specimen, measurement.measure, measurement.value);
    }
    _structuralRevision += 1;
    return specimen;
  }

  bool retireNow(Specimen specimen) {
    if (!_registry.contains(specimen)) return false;
    for (final MeasureColumnBase column in _columns.values) {
      column.removeSlot(specimen.slot);
    }
    final bool retired = _registry.retire(specimen);
    if (retired) _structuralRevision += 1;
    return retired;
  }

  bool contains(Specimen specimen) => _registry.contains(specimen);
  Specimen? specimenAtSlot(int slot) => _registry.atSlot(slot);

  MeasureColumn<T> _column<T extends Object>(Measure<T> measure) {
    registerMeasure<T>(measure);
    return _columns[measure.erased]! as MeasureColumn<T>;
  }

  MeasureColumnView? columnView(Measure<Object> measure) => _columns[measure];

  bool has<T extends Object>(Specimen specimen, Measure<T> measure) =>
      contains(specimen) && _columns[measure.erased]?.containsSlot(specimen.slot) == true;

  bool hasErased(Specimen specimen, Measure<Object> measure) =>
      contains(specimen) && _columns[measure]?.containsSlot(specimen.slot) == true;

  T? read<T extends Object>(Specimen specimen, Measure<T> measure) {
    if (!contains(specimen)) return null;
    return (_columns[measure.erased] as MeasureColumn<T>?)?.read(specimen.slot);
  }

  T require<T extends Object>(Specimen specimen, Measure<T> measure) {
    if (!contains(specimen)) throw StateError('Stale specimen: $specimen');
    return _column<T>(measure).require(specimen.slot);
  }

  bool write<T extends Object>(Specimen specimen, Measure<T> measure, T value) {
    if (!contains(specimen)) throw StateError('Stale specimen: $specimen');
    final bool inserted = _column<T>(measure).write(specimen.slot, value);
    if (inserted) _structuralRevision += 1;
    return inserted;
  }

  bool writeErased(Specimen specimen, Measure<Object> measure, Object value) =>
      write<Object>(specimen, measure, value);

  bool remove<T extends Object>(Specimen specimen, Measure<T> measure) {
    if (!contains(specimen)) return false;
    final bool removed = _columns[measure.erased]?.removeSlot(specimen.slot) ?? false;
    if (removed) _structuralRevision += 1;
    return removed;
  }

  Cohort cohort(CohortLens lens) {
    return Cohort(this, lens);
  }

  int commit() => transaction.commit(this);

  Map<String, Object?> snapshot() {
    final List<Map<String, Object?>> rows = <Map<String, Object?>>[];
    for (final Specimen specimen in specimens) {
      final Map<String, Object?> values = <String, Object?>{};
      for (final MapEntry<Measure<Object>, MeasureColumnBase> entry in _columns.entries) {
        final Object? value = entry.value.readObject(specimen.slot);
        if (value != null) {
          values[entry.key.name] = entry.key.encode?.call(value) ?? value.toString();
        }
      }
      rows.add(<String, Object?>{
        'slot': specimen.slot,
        'generation': specimen.generation,
        'measurements': values,
      });
    }
    return <String, Object?>{
      'schema': 'veyramesh-study-snapshot/v1',
      'seed': seed,
      'structural_revision': structuralRevision,
      'specimens': rows,
    };
  }
}
