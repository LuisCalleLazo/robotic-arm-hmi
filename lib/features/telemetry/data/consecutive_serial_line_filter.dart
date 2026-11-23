class ConsecutiveSerialLineFilter {
  String? _lastLine;

  bool accept(String line) {
    final normalized = line.trim();
    if (normalized.isEmpty || normalized == _lastLine) return false;
    _lastLine = normalized;
    return true;
  }

  void reset() {
    _lastLine = null;
  }
}
