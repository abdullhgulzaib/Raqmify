// Shared ID extraction helper to ensure robust and consistent identifier parsing across all models.
// Handles plain String, Map containing '_id' or 'id', null, and empty values.
String extractId(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  if (value is num) return value.toString().trim();
  if (value is Map) {
    if (value['_id'] != null) {
      final idVal = value['_id'];
      if (idVal is String) return idVal.trim();
      if (idVal is Map) return extractId(idVal);
      final s = idVal.toString().trim();
      if (s.isNotEmpty && !s.startsWith('{')) return s;
    }
    if (value['id'] != null) {
      final idVal = value['id'];
      if (idVal is String) return idVal.trim();
      if (idVal is Map) return extractId(idVal);
      final s = idVal.toString().trim();
      if (s.isNotEmpty && !s.startsWith('{')) return s;
    }
    if (value['userId'] != null) {
      final idVal = value['userId'];
      if (idVal is String) return idVal.trim();
      if (idVal is Map) return extractId(idVal);
      final s = idVal.toString().trim();
      if (s.isNotEmpty && !s.startsWith('{')) return s;
    }
  }
  return '';
}
