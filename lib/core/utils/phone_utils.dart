/// Utility for normalizing and comparing phone numbers.
///
/// Device contacts and stored numbers may differ in format
/// (e.g. +8801712XXXXXX vs 01712XXXXXX vs 8801712XXXXXX).
/// Normalize both sides before comparing.
class PhoneUtils {
  PhoneUtils._();

  /// Strips all non-digit characters from a phone string.
  static String _digitsOnly(String phone) => phone.replaceAll(RegExp(r'\D'), '');

  /// Normalize a Bangladeshi phone number to the 880-prefix format.
  ///
  /// Handles:
  ///  01712XXXXXX  → 8801712XXXXXX
  ///  +8801712XXXXXX → 8801712XXXXXX
  ///  8801712XXXXXX → 8801712XXXXXX (already normalized)
  static String normalize(String phone) {
    final digits = _digitsOnly(phone);

    if (digits.length == 11 && digits.startsWith('0')) {
      // Local BD format: 01712XXXXXX → 8801712XXXXXX
      return '880${digits.substring(1)}';
    }

    if (digits.length == 14 && digits.startsWith('00880')) {
      // International with 00 prefix: 008801712XXXXXX
      return digits.substring(2);
    }

    if (digits.length == 13 && digits.startsWith('880')) {
      // Already normalized
      return digits;
    }

    // Fallback: return raw digits
    return digits;
  }

  /// Returns `true` if both phone numbers refer to the same line.
  static bool match(String a, String b) => normalize(a) == normalize(b);

  /// Returns a lookup set of normalized phone numbers for fast dedup checks.
  static Set<String> normalizedSet(Iterable<String> phones) =>
      phones.map(normalize).toSet();

  /// Canonical E.164 format for Bangladesh: +8801712XXXXXX.
  ///
  /// Use this when saving phone numbers to Firestore so every record uses
  /// a single, query-friendly format — like WhatsApp.
  ///
  /// Input → Output:
  ///   01712XXXXXX  → +8801712XXXXXX
  ///  +8801712XXXXXX → +8801712XXXXXX
  ///   8801712XXXXXX → +8801712XXXXXX
  ///  008801712XXXXXX → +8801712XXXXXX
  static String toCanonical(String phone) {
    final digits = _digitsOnly(phone);

    if (digits.length == 11 && digits.startsWith('0')) {
      // Local BD: 01712XXXXXX → +8801712XXXXXX
      return '+880${digits.substring(1)}';
    }

    if (digits.length == 14 && digits.startsWith('00880')) {
      // 008801712XXXXXX → +8801712XXXXXX
      return '+${digits.substring(2)}';
    }

    if (digits.length == 13 && digits.startsWith('880')) {
      // Already has country code: 8801712XXXXXX → +8801712XXXXXX
      return '+$digits';
    }

    // Fallback: raw digits won't be clean, but returning them is better
    // than silently storing garbage.
    return digits;
  }
}
