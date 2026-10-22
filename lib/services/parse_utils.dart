/// "1,234.50", "$12", " 7 " -> number; anything unparseable -> null.
double? parseNumber(String? s) {
  if (s == null) return null;
  final v = s.trim().replaceAll(',', '').replaceAll(RegExp(r'[\s$¥€£]'), '');
  if (v.isEmpty) return null;
  return double.tryParse(v);
}

/// Accepts yyyy-MM-dd (also with / and an optional time) and dd/MM/yyyy
/// (day first, the SG/MY convention). Returns a date-only value, or null.
DateTime? parseDateLoose(String? s) {
  if (s == null) return null;
  final v = s.trim();
  if (v.isEmpty) return null;
  final iso = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(v);
  if (iso != null) {
    return _ymd(int.parse(iso.group(1)!), int.parse(iso.group(2)!), int.parse(iso.group(3)!));
  }
  final dmy = RegExp(r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})').firstMatch(v);
  if (dmy != null) {
    return _ymd(int.parse(dmy.group(3)!), int.parse(dmy.group(2)!), int.parse(dmy.group(1)!));
  }
  return null;
}

DateTime? _ymd(int y, int m, int d) {
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  final dt = DateTime(y, m, d);
  return dt.month == m ? dt : null; // rejects 31 Feb etc.
}
