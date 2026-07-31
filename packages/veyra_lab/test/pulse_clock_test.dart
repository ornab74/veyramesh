// SPDX-License-Identifier: GPL-3.0-only

import 'package:test/test.dart';
import 'package:veyra_lab/veyra_lab.dart';

void main() {
  test('pulse clock clamps frames and bounds catch-up', () {
    final PulseClock clock = PulseClock(frequency: 20, maximumSteps: 3, maximumFrameSeconds: 0.25);
    final PulseBatch batch = clock.advance(1);
    expect(batch.steps, 3);
    expect(batch.droppedSeconds, greaterThan(0));
    expect(batch.interpolation, inInclusiveRange(0, 1));
  });
}
