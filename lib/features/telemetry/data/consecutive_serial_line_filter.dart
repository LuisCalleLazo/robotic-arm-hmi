class ConsecutiveSerialLineFilter {
  String? _lastLine;

  bool accept(String line, {bool allowRepeated = false}) {
    final normalized = line.trim();
    if (normalized.isEmpty) return false;
    if (!allowRepeated && normalized == _lastLine) return false;
    _lastLine = normalized;
    return true;
  }

  void reset() {
    _lastLine = null;
  }
}
