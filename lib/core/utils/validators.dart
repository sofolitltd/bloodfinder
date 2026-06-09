class Validators {
  Validators._();

  static String? required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  static String? Function(String?) minLength(int min) => (String? value) =>
      value != null && value.length >= min ? null : 'Minimum $min characters';

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value.trim()) ? null : 'Invalid email';
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (value.length < 8) return 'Minimum 8 characters';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (value.trim().length < 2) return 'Minimum 2 characters';
    return null;
  }

  static String? mobile(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final phoneRegex = RegExp(r'^\+?[\d\s-]{7,15}$');
    return phoneRegex.hasMatch(value.trim()) ? null : 'Invalid number';
  }

  static String? Function(String?) notEmpty(String fieldName) =>
      (String? value) =>
          value == null || value.trim().isEmpty ? '$fieldName is required' : null;

  static String? Function(String?) dropdown(dynamic currentValue) =>
      (String? value) => currentValue == null ? 'Required' : null;
}
