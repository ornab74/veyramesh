// SPDX-License-Identifier: GPL-3.0-only

int _nextMeasureId = 0;

final class Measure<T extends Object> {
  Measure(
    this.name, {
    this.encode,
    this.decode,
    this.copy,
    this.unit,
    this.description,
  }) : id = _nextMeasureId++;

  final int id;
  final String name;
  final String? unit;
  final String? description;
  final Object? Function(T value)? encode;
  final T Function(Object? value)? decode;
  final T Function(T value)? copy;

  Measurement<T> call(T value) => Measurement<T>(this, value);
  Measure<Object> get erased => this as Measure<Object>;

  @override
  bool operator ==(Object other) => other is Measure<Object> && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Measure<$T>($name#$id)';
}

final class Measurement<T extends Object> {
  const Measurement(this.measure, this.value);

  final Measure<T> measure;
  final T value;

  Measurement<Object> get erased => this as Measurement<Object>;
}

abstract interface class MeasureColumnView {
  int get length;
  Iterable<int> get slots;
  bool containsSlot(int slot);
  Object? readObject(int slot);
}

abstract interface class MeasureColumnBase implements MeasureColumnView {
  Measure<Object> get erasedMeasure;
  bool removeSlot(int slot);
}

final class MeasureColumn<T extends Object> implements MeasureColumnBase {
  MeasureColumn(this.measure);

  final Measure<T> measure;
  final List<int> _sparse = <int>[];
  final List<int> _denseSlots = <int>[];
  final List<T> _denseValues = <T>[];

  @override
  Measure<Object> get erasedMeasure => measure.erased;
  @override
  int get length => _denseSlots.length;
  @override
  Iterable<int> get slots => _denseSlots;

  void _ensure(int slot) {
    while (_sparse.length <= slot) _sparse.add(-1);
  }

  int _denseIndex(int slot) {
    if (slot < 0 || slot >= _sparse.length) return -1;
    final int dense = _sparse[slot];
    if (dense < 0 || dense >= _denseSlots.length) return -1;
    return _denseSlots[dense] == slot ? dense : -1;
  }

  @override
  bool containsSlot(int slot) => _denseIndex(slot) >= 0;

  bool write(int slot, T value) {
    _ensure(slot);
    final int dense = _denseIndex(slot);
    if (dense >= 0) {
      _denseValues[dense] = value;
      return false;
    }
    _sparse[slot] = _denseSlots.length;
    _denseSlots.add(slot);
    _denseValues.add(value);
    return true;
  }

  T? read(int slot) {
    final int dense = _denseIndex(slot);
    return dense < 0 ? null : _denseValues[dense];
  }

  T require(int slot) {
    final T? value = read(slot);
    if (value == null) {
      throw StateError('Slot $slot has no ${measure.name} measurement.');
    }
    return value;
  }

  @override
  Object? readObject(int slot) => read(slot);

  @override
  bool removeSlot(int slot) {
    final int dense = _denseIndex(slot);
    if (dense < 0) return false;
    final int last = _denseSlots.length - 1;
    final int movedSlot = _denseSlots[last];
    if (dense != last) {
      _denseSlots[dense] = movedSlot;
      _denseValues[dense] = _denseValues[last];
      _sparse[movedSlot] = dense;
    }
    _denseSlots.removeLast();
    _denseValues.removeLast();
    _sparse[slot] = -1;
    return true;
  }
}
