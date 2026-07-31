// SPDX-License-Identifier: GPL-3.0-only

import 'package:test/test.dart';
import 'package:veyra_lab/veyra_lab.dart';

void main() {
  group('StudySpace', () {
    test('retired specimen handles cannot access recycled slots', () {
      final StudySpace space = StudySpace();
      final Measure<String> label = Measure<String>('label');
      final Specimen first = space.createNow(<Measurement<Object>>[label('first').erased]);
      expect(space.require(first, label), 'first');
      expect(space.retireNow(first), isTrue);
      final Specimen second = space.createNow(<Measurement<Object>>[label('second').erased]);
      expect(second.slot, first.slot);
      expect(second.generation, isNot(first.generation));
      expect(space.read(first, label), isNull);
      expect(space.require(second, label), 'second');
    });

    test('cohort refreshes after structural edits', () {
      final StudySpace space = StudySpace();
      final Measure<int> score = Measure<int>('score');
      final Cohort scored = space.cohort(CohortLens.all(<Measure<Object>>[score.erased]));
      final Specimen specimen = space.createNow();
      expect(scored.length, 0);
      space.write(specimen, score, 5);
      expect(scored.length, 1);
      space.remove(specimen, score);
      expect(scored.length, 0);
    });
  });
}
