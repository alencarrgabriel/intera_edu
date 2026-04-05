class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email é obrigatório';
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value)) {
      return 'Informe um email válido';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Senha é obrigatória';
    if (value.length < 8) return 'A senha deve ter pelo menos 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Deve conter uma letra maiúscula';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Deve conter uma letra minúscula';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Deve conter um número';
    if (!RegExp(r'[!@#\$%\^&\*]').hasMatch(value)) return 'Deve conter um caractere especial';
    return null;
  }

  static String? required(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) return '$fieldName é obrigatório';
    return null;
  }

  static String? otpCode(String? value) {
    if (value == null || value.isEmpty) return 'Informe o código de verificação';
    if (value.length != 6) return 'O código deve ter 6 dígitos';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'O código deve conter apenas números';
    return null;
  }
}
