import 'dart:collection';

/// Buffer circular de capacidad fija: al llenarse descarta el elemento más viejo.
class RingBuffer<T> {
  RingBuffer(this.capacity) : assert(capacity > 0);

  final int capacity;
  final Queue<T> _items = Queue<T>();

  int get length => _items.length;
  bool get isEmpty => _items.isEmpty;
  T? get last => _items.isEmpty ? null : _items.last;

  void add(T value) {
    if (_items.length >= capacity) _items.removeFirst();
    _items.addLast(value);
  }

  void clear() => _items.clear();

  /// Copia inmutable, de más viejo a más nuevo.
  List<T> toList() => List<T>.unmodifiable(_items);
}
