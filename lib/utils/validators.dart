/// Shared `TextFormField` validators. All return a translation-ready plain
/// string; screens are expected to have already localized [emptyMessage] via
/// `.tr()` before passing it in, keeping this file locale-agnostic.
class Validators {
  Validators._();

  static String? required(String? value, String emptyMessage) {
    if (value == null || value.trim().isEmpty) return emptyMessage;
    return null;
  }

  static String? minLength(
    String? value,
    int min,
    String emptyMessage,
    String tooShortMessage,
  ) {
    final requiredError = required(value, emptyMessage);
    if (requiredError != null) return requiredError;
    if (value!.trim().length < min) return tooShortMessage;
    return null;
  }

  static String? matches(
    String? value,
    String? other,
    String mismatchMessage,
  ) {
    if (value != other) return mismatchMessage;
    return null;
  }

  static String? nonNegativeNumber(
    String? value,
    String emptyMessage,
    String invalidMessage,
  ) {
    final requiredError = required(value, emptyMessage);
    if (requiredError != null) return requiredError;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed < 0) return invalidMessage;
    return null;
  }

  static String? positiveNumber(
    String? value,
    String emptyMessage,
    String invalidMessage,
  ) {
    final requiredError = required(value, emptyMessage);
    if (requiredError != null) return requiredError;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed <= 0) return invalidMessage;
    return null;
  }
}
