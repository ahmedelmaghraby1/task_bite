abstract class AppValidations {
  static String? validator(String? text, String message) {
    if (text == null || text.isEmpty) {
      return message;
    } else {
      return null;
    }
  }
}
