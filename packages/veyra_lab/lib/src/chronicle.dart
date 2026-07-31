// SPDX-License-Identifier: GPL-3.0-only

import 'dart:convert';

final class Observation {
  const Observation({
    required this.pulse,
    required this.channel,
    required this.value,
    this.protocol,
    this.tags = const <String, String>{},
  });

  final int pulse;
  final String channel;
  final Object? value;
  final String? protocol;
  final Map<String, String> tags;

  Map<String, Object?> toJson() => <String, Object?>{
        'pulse': pulse,
        'channel': channel,
        'value': value,
        if (protocol != null) 'protocol': protocol,
        if (tags.isNotEmpty) 'tags': tags,
      };
}

final class PulseRecord {
  const PulseRecord({
    required this.index,
    required this.deltaSeconds,
    required this.wallSeconds,
    required this.committedEdits,
    required this.protocolDurationsMicros,
  });

  final int index;
  final double deltaSeconds;
  final double wallSeconds;
  final int committedEdits;
  final Map<String, int> protocolDurationsMicros;

  Map<String, Object?> toJson() => <String, Object?>{
        'index': index,
        'delta_seconds': deltaSeconds,
        'wall_seconds': wallSeconds,
        'committed_edits': committedEdits,
        'protocol_durations_micros': protocolDurationsMicros,
      };
}

final class Chronicle {
  Chronicle({required this.studyName, required this.seed});

  final String studyName;
  final int seed;
  final DateTime createdAt = DateTime.now().toUtc();
  final List<PulseRecord> pulses = <PulseRecord>[];
  final List<Observation> observations = <Observation>[];
  final Map<String, Object?> metadata = <String, Object?>{};

  void observe(
    int pulse,
    String channel,
    Object? value, {
    String? protocol,
    Map<String, String> tags = const <String, String>{},
  }) {
    observations.add(Observation(
      pulse: pulse,
      channel: channel,
      value: value,
      protocol: protocol,
      tags: tags,
    ));
  }

  Iterable<Observation> channel(String name) =>
      observations.where((Observation observation) => observation.channel == name);

  Map<String, Object?> toJson() => <String, Object?>{
        'schema': 'veyramesh-chronicle/v1',
        'study_name': studyName,
        'seed': seed,
        'created_at': createdAt.toIso8601String(),
        'metadata': metadata,
        'pulses': pulses.map((PulseRecord p) => p.toJson()).toList(),
        'observations': observations.map((Observation o) => o.toJson()).toList(),
      };

  String encode({bool pretty = true}) =>
      pretty ? const JsonEncoder.withIndent('  ').convert(toJson()) : jsonEncode(toJson());
}
