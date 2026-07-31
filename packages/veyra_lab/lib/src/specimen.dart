// SPDX-License-Identifier: GPL-3.0-only

/// Stable handle for one subject of observation.
final class Specimen implements Comparable<Specimen> {
  const Specimen(this.slot, this.generation);

  final int slot;
  final int generation;

  @override
  int compareTo(Specimen other) {
    final int bySlot = slot.compareTo(other.slot);
    return bySlot == 0 ? generation.compareTo(other.generation) : bySlot;
  }

  @override
  bool operator ==(Object other) =>
      other is Specimen && other.slot == slot && other.generation == generation;

  @override
  int get hashCode => Object.hash(slot, generation);

  @override
  String toString() => 'Specimen($slot:$generation)';
}

final class SpecimenRegistry {
  final List<int> _generations = <int>[];
  final List<bool> _active = <bool>[];
  final List<int> _available = <int>[];
  int _activeCount = 0;

  int get activeCount => _activeCount;
  int get capacity => _generations.length;

  Specimen create() {
    if (_available.isNotEmpty) {
      final int slot = _available.removeLast();
      _active[slot] = true;
      _activeCount += 1;
      return Specimen(slot, _generations[slot]);
    }
    final int slot = _generations.length;
    _generations.add(0);
    _active.add(true);
    _activeCount += 1;
    return Specimen(slot, 0);
  }

  bool contains(Specimen specimen) =>
      specimen.slot >= 0 &&
      specimen.slot < _generations.length &&
      _active[specimen.slot] &&
      _generations[specimen.slot] == specimen.generation;

  Specimen? atSlot(int slot) {
    if (slot < 0 || slot >= _active.length || !_active[slot]) return null;
    return Specimen(slot, _generations[slot]);
  }

  bool retire(Specimen specimen) {
    if (!contains(specimen)) return false;
    _active[specimen.slot] = false;
    _generations[specimen.slot] += 1;
    _available.add(specimen.slot);
    _activeCount -= 1;
    return true;
  }

  Iterable<Specimen> get active sync* {
    for (int slot = 0; slot < _active.length; slot += 1) {
      final Specimen? specimen = atSlot(slot);
      if (specimen != null) yield specimen;
    }
  }
}
