/// String formatting utilities.
class StringUtils {
  StringUtils._();

  /// Convert a string to Title Case.
  ///
  /// "most arafa alam" → "Most Arafa Alam"
  /// "john" → "John"
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .toLowerCase()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Format a full name from [firstName] and [lastName] in Title Case.
  static String formatFullName(String? firstName, String? lastName) {
    final name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return name.isEmpty ? 'Unknown' : toTitleCase(name);
  }
}
