/// Normalizes phone numbers to international digits without leading '+' or '00'.
/// Example (Pakistan): 0300 1234567, +92 300 1234567, 00923001234567 -> 923001234567
String normalizePhoneToInternationalDigits(String rawPhone) {
  String cleaned = rawPhone.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
  if (cleaned.startsWith('+')) {
    cleaned = cleaned.substring(1);
  }
  if (cleaned.startsWith('00')) {
    cleaned = cleaned.substring(2);
  }
  if (cleaned.startsWith('0') && cleaned.length == 11) {
    cleaned = '92${cleaned.substring(1)}';
  }
  return cleaned;
}

/// Builds the WhatsApp direct URI and wa.me fallback URI.
String buildWhatsAppDirectUrl(String phone, String message) {
  final normalized = normalizePhoneToInternationalDigits(phone);
  final encodedMsg = Uri.encodeComponent(message);
  if (normalized.isNotEmpty) {
    return 'whatsapp://send?phone=$normalized&text=$encodedMsg';
  }
  return 'whatsapp://send?text=$encodedMsg';
}

String buildWhatsAppWebUrl(String phone, String message) {
  final normalized = normalizePhoneToInternationalDigits(phone);
  final encodedMsg = Uri.encodeComponent(message);
  if (normalized.isNotEmpty) {
    return 'https://wa.me/$normalized?text=$encodedMsg';
  }
  return 'https://wa.me/?text=$encodedMsg';
}
