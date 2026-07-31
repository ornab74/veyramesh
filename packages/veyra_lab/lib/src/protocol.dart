// SPDX-License-Identifier: GPL-3.0-only

import 'chronicle.dart';
import 'study_space.dart';

enum ProtocolPhase { preparation, intervention, observation, analysis, presentation }

typedef ProtocolBody = void Function(ProtocolContext context);

final class Protocol {
  Protocol({
    required this.name,
    required this.phase,
    required this.run,
    this.after = const <String>{},
    this.before = const <String>{},
    this.priority = 0,
    this.enabled = true,
    this.summary = '',
  });

  final String name;
  final ProtocolPhase phase;
  final ProtocolBody run;
  final Set<String> after;
  final Set<String> before;
  final int priority;
  final bool enabled;
  final String summary;
}

final class ProtocolContext {
  const ProtocolContext({
    required this.space,
    required this.chronicle,
    required this.pulse,
    required this.deltaSeconds,
    required this.interpolation,
    required this.phase,
  });

  final StudySpace space;
  final Chronicle chronicle;
  final int pulse;
  final double deltaSeconds;
  final double interpolation;
  final ProtocolPhase phase;
}

final class ProtocolGraph {
  final List<Protocol> _protocols = <Protocol>[];
  List<Protocol>? _ordered;

  List<Protocol> get protocols => List<Protocol>.unmodifiable(_protocols);

  void add(Protocol protocol) {
    if (_protocols.any((Protocol p) => p.name == protocol.name)) {
      throw ArgumentError('Protocol name already registered: ${protocol.name}');
    }
    _protocols.add(protocol);
    _ordered = null;
  }

  List<Protocol> ordered() {
    if (_ordered != null) return _ordered!;
    final Map<String, Protocol> byName = <String, Protocol>{
      for (final Protocol protocol in _protocols) protocol.name: protocol,
    };
    final Map<String, Set<String>> outgoing = <String, Set<String>>{
      for (final Protocol protocol in _protocols) protocol.name: <String>{},
    };
    final Map<String, int> incoming = <String, int>{
      for (final Protocol protocol in _protocols) protocol.name: 0,
    };

    void connect(String first, String second) {
      if (!byName.containsKey(first) || !byName.containsKey(second)) {
        throw StateError('Protocol dependency references an unknown name: $first -> $second');
      }
      if (outgoing[first]!.add(second)) incoming[second] = incoming[second]! + 1;
    }

    for (final Protocol protocol in _protocols) {
      for (final String dependency in protocol.after) connect(dependency, protocol.name);
      for (final String successor in protocol.before) connect(protocol.name, successor);
    }

    int phaseIndex(Protocol p) => ProtocolPhase.values.indexOf(p.phase);
    int compare(Protocol a, Protocol b) {
      final int phase = phaseIndex(a).compareTo(phaseIndex(b));
      if (phase != 0) return phase;
      final int priority = b.priority.compareTo(a.priority);
      if (priority != 0) return priority;
      return a.name.compareTo(b.name);
    }

    final List<Protocol> ready = _protocols
        .where((Protocol p) => incoming[p.name] == 0)
        .toList()..sort(compare);
    final List<Protocol> result = <Protocol>[];
    while (ready.isNotEmpty) {
      final Protocol current = ready.removeAt(0);
      result.add(current);
      for (final String next in outgoing[current.name]!) {
        incoming[next] = incoming[next]! - 1;
        if (incoming[next] == 0) {
          ready.add(byName[next]!);
          ready.sort(compare);
        }
      }
    }
    if (result.length != _protocols.length) {
      final List<String> cycle = incoming.entries
          .where((MapEntry<String, int> e) => e.value > 0)
          .map((MapEntry<String, int> e) => e.key)
          .toList()..sort();
      throw StateError('Protocol dependency cycle: ${cycle.join(', ')}');
    }
    _ordered = List<Protocol>.unmodifiable(result);
    return _ordered!;
  }
}
