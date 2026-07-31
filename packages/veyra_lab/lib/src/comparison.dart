// SPDX-License-Identifier: GPL-3.0-only

import 'chronicle.dart';

final class ObservationDelta {
  const ObservationDelta({
    required this.pulse,
    required this.channel,
    required this.left,
    required this.right,
    required this.equal,
  });

  final int pulse;
  final String channel;
  final Object? left;
  final Object? right;
  final bool equal;
}

final class ComparativeRun {
  const ComparativeRun(this.left, this.right);

  final Chronicle left;
  final Chronicle right;

  List<ObservationDelta> compareChannel(String channel) {
    final Map<int, Observation> a = <int, Observation>{
      for (final Observation observation in left.channel(channel))
        observation.pulse: observation,
    };
    final Map<int, Observation> b = <int, Observation>{
      for (final Observation observation in right.channel(channel))
        observation.pulse: observation,
    };
    final List<int> pulses = <int>{...a.keys, ...b.keys}.toList()..sort();
    return <ObservationDelta>[
      for (final int pulse in pulses)
        ObservationDelta(
          pulse: pulse,
          channel: channel,
          left: a[pulse]?.value,
          right: b[pulse]?.value,
          equal: a[pulse]?.value == b[pulse]?.value,
        ),
    ];
  }
}
