/// Mirrors stripNepalPhonePrefix() in dentaldb/components/patients/PatientModal.tsx:
/// the backend stores phone numbers with a +977 prefix; the form only shows
/// and edits the 10-digit local number.
String stripNepalPhonePrefix(String? value) {
  if (value == null || value.isEmpty) return '';
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= 10) return digits;
  return digits.substring(digits.length - 10);
}

/// Re-adds the +977 prefix before sending to the API, same as the web form's
/// submit payload mapping (`phone ? \`+977\${phone}\` : null`).
String? toNepalPhonePayload(String? localDigits) {
  if (localDigits == null || localDigits.trim().isEmpty) return null;
  return '+977${localDigits.trim()}';
}

bool isValidNepalLocalPhone(String value) => RegExp(r'^\d{10}$').hasMatch(value);