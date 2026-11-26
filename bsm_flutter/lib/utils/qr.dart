/// डेमो QR मैट्रिक्स — पास आईडी से हर बार वही पैटर्न बनता है।
/// प्रोडक्शन में सर्वर से हस्ताक्षरित QR इमेज आएगी (package:qr_flutter)।
List<List<bool>> qrMatrix(String value, {int size = 25}) {
  final grid = List.generate(size, (_) => List<bool>.filled(size, false));

  var h = 2166136261; // FNV-1a (32-bit)
  for (final unit in value.codeUnits) {
    h ^= unit;
    h = (h * 16777619) & 0xFFFFFFFF;
  }
  var s = h == 0 ? 1 : h;

  bool nextBit() {
    s ^= (s << 13) & 0xFFFFFFFF;
    s ^= s >> 17;
    s ^= (s << 5) & 0xFFFFFFFF;
    s &= 0xFFFFFFFF;
    return ((s >> 8) & 0xFFFFFF) / 16777216.0 > 0.5;
  }

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      grid[y][x] = nextBit();
    }
  }

  void finder(int ox, int oy) {
    for (var y = 0; y < 7; y++) {
      for (var x = 0; x < 7; x++) {
        final edge = x == 0 || x == 6 || y == 0 || y == 6;
        final core = x >= 2 && x <= 4 && y >= 2 && y <= 4;
        grid[oy + y][ox + x] = edge || core;
      }
    }
  }

  finder(0, 0);
  finder(size - 7, 0);
  finder(0, size - 7);

  for (var i = 0; i < 8; i++) {
    grid[7][i] = false;
    grid[i][7] = false;
    grid[7][size - 1 - i] = false;
    grid[i][size - 8] = false;
    grid[size - 8][i] = false;
    grid[size - 1 - i][7] = false;
  }
  return grid;
}
