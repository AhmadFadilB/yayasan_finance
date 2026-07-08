// Stub interface untuk mendefinisikan saveAndLaunchFile pada multi-platform.
// Dart akan memilih file implementasi yang tepat secara dinamis berdasarkan platform kueri.
Future<void> saveAndLaunchFile(List<int> bytes, String fileName) {
  throw UnimplementedError('Platform ini tidak didukung untuk menyimpan file Excel.');
}
