class Validators {
  Validators._();

  static bool isValidEmail(String value) {
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim());
  }

  static bool isNotEmpty(String value) => value.trim().isNotEmpty;

  static bool isValidPhone(String value) {
    return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value.trim());
  }
}
