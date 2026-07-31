// SPDX-License-Identifier: GPL-3.0-only

import 'measure.dart';
import 'specimen.dart';
import 'study_space.dart';

typedef CohortPredicate = bool Function(StudySpace space, Specimen specimen);

final class CohortLens {
  CohortLens({
    Iterable<Measure<Object>> require = const <Measure<Object>>[],
    Iterable<Measure<Object>> exclude = const <Measure<Object>>[],
    this.predicate,
    this.label = 'anonymous-cohort',
  })  : required = Set<Measure<Object>>.unmodifiable(require),
        excluded = Set<Measure<Object>>.unmodifiable(exclude);

  factory CohortLens.all(
    Iterable<Measure<Object>> required, {
    String label = 'all-measures',
  }) =>
      CohortLens(require: required, label: label);

  final Set<Measure<Object>> required;
  final Set<Measure<Object>> excluded;
  final CohortPredicate? predicate;
  final String label;

  bool matches(StudySpace space, Specimen specimen) {
    for (final Measure<Object> measure in required) {
      if (!space.hasErased(specimen, measure)) return false;
    }
    for (final Measure<Object> measure in excluded) {
      if (space.hasErased(specimen, measure)) return false;
    }
    return predicate?.call(space, specimen) ?? true;
  }
}

final class Cohort {
  Cohort(this._space, this.lens);

  final StudySpace _space;
  final CohortLens lens;
  int _revision = -1;
  List<Specimen> _members = <Specimen>[];

  List<Specimen> get members {
    if (_revision != _space.structuralRevision) refresh();
    return List<Specimen>.unmodifiable(_members);
  }

  int get length => members.length;

  void refresh() {
    Iterable<Specimen> candidates = _space.specimens;
    MeasureColumnView? smallest;
    for (final Measure<Object> measure in lens.required) {
      final MeasureColumnView? column = _space.columnView(measure);
      if (column == null) {
        _members = <Specimen>[];
        _revision = _space.structuralRevision;
        return;
      }
      if (smallest == null || column.length < smallest.length) smallest = column;
    }
    if (smallest != null) {
      candidates = smallest.slots
          .map(_space.specimenAtSlot)
          .whereType<Specimen>();
    }
    _members = candidates.where((Specimen s) => lens.matches(_space, s)).toList()
      ..sort();
    _revision = _space.structuralRevision;
  }
}
