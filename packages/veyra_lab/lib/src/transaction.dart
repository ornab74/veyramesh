// SPDX-License-Identifier: GPL-3.0-only

import 'measure.dart';
import 'specimen.dart';
import 'study_space.dart';

sealed class StudyEdit {
  const StudyEdit();
  void apply(StudySpace space);
}

final class BirthEdit extends StudyEdit {
  BirthEdit(this.measurements);
  final List<Measurement<Object>> measurements;
  Specimen? created;

  @override
  void apply(StudySpace space) {
    created = space.createNow(measurements);
  }
}

final class RetirementEdit extends StudyEdit {
  const RetirementEdit(this.specimen);
  final Specimen specimen;

  @override
  void apply(StudySpace space) => space.retireNow(specimen);
}

final class WriteEdit<T extends Object> extends StudyEdit {
  const WriteEdit(this.specimen, this.measure, this.value);
  final Specimen specimen;
  final Measure<T> measure;
  final T value;

  @override
  void apply(StudySpace space) => space.write(specimen, measure, value);
}

final class RemoveEdit<T extends Object> extends StudyEdit {
  const RemoveEdit(this.specimen, this.measure);
  final Specimen specimen;
  final Measure<T> measure;

  @override
  void apply(StudySpace space) => space.remove(specimen, measure);
}

final class StudyTransaction {
  final List<StudyEdit> _edits = <StudyEdit>[];

  bool get isEmpty => _edits.isEmpty;
  int get length => _edits.length;

  BirthEdit spawn(Iterable<Measurement<Object>> measurements) {
    final BirthEdit edit = BirthEdit(List<Measurement<Object>>.from(measurements));
    _edits.add(edit);
    return edit;
  }

  void retire(Specimen specimen) => _edits.add(RetirementEdit(specimen));

  void write<T extends Object>(Specimen specimen, Measure<T> measure, T value) {
    _edits.add(WriteEdit<T>(specimen, measure, value));
  }

  void remove<T extends Object>(Specimen specimen, Measure<T> measure) {
    _edits.add(RemoveEdit<T>(specimen, measure));
  }

  int commit(StudySpace space) {
    final List<StudyEdit> pending = List<StudyEdit>.from(_edits);
    _edits.clear();
    for (final StudyEdit edit in pending) edit.apply(space);
    return pending.length;
  }

  void discard() => _edits.clear();
}
