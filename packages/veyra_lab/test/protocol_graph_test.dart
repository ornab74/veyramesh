// SPDX-License-Identifier: GPL-3.0-only

import 'package:test/test.dart';
import 'package:veyra_lab/veyra_lab.dart';

void main() {
  test('protocol graph honors dependencies and phases', () {
    final ProtocolGraph graph = ProtocolGraph();
    void noop(ProtocolContext _) {}
    graph.add(Protocol(name: 'observe', phase: ProtocolPhase.observation, run: noop, after: <String>{'move'}));
    graph.add(Protocol(name: 'move', phase: ProtocolPhase.intervention, run: noop, after: <String>{'prepare'}));
    graph.add(Protocol(name: 'prepare', phase: ProtocolPhase.preparation, run: noop));
    expect(graph.ordered().map((Protocol p) => p.name), <String>['prepare', 'move', 'observe']);
  });

  test('protocol graph rejects cycles', () {
    final ProtocolGraph graph = ProtocolGraph();
    void noop(ProtocolContext _) {}
    graph.add(Protocol(name: 'a', phase: ProtocolPhase.analysis, run: noop, after: <String>{'b'}));
    graph.add(Protocol(name: 'b', phase: ProtocolPhase.analysis, run: noop, after: <String>{'a'}));
    expect(graph.ordered, throwsStateError);
  });
}
