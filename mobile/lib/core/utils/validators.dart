abstract final class Validators {
  static String? required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;
  static String? email(String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Enter a valid email';
  static String? password(String? value) =>
      (value?.length ?? 0) >= 8 ? null : 'Use at least 8 characters';
  static String? phone(String? value) =>
      RegExp(r'^\+?[0-9 ()-]{7,32}$').hasMatch(value ?? '')
      ? null
      : 'Enter a valid phone number';
  static String? age(String? value) {
    final age = int.tryParse(value ?? '');
    return age != null && age >= 0 && age <= 120 ? null : 'Enter a valid age';
  }
}
