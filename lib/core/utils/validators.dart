class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Must contain an uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Must contain a lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Must contain a number';
    if (!RegExp(r'[!@#\$%\^&\*]').hasMatch(value)) return 'Must contain a special character';
    return null;
  }

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? otpCode(String? value) {
    if (value == null || value.isEmpty) return 'Enter the verification code';
    if (value.length != 6) return 'Code must be 6 digits';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'Code must contain only numbers';
    return null;
  }
}
