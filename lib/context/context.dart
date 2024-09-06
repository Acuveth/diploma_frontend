import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static SharedPreferences? _preferences;

  static const _keyIsLoggedIn = 'isLoggedIn';
  static const _keyUserID = 'userID';
  static const _keyIsDarkMode = 'isDarkMode';

  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

  static Future setLoggedIn(bool isLoggedIn) async =>
      await _preferences?.setBool(_keyIsLoggedIn, isLoggedIn);

  static bool isLoggedIn() => _preferences?.getBool(_keyIsLoggedIn) ?? false;

  static Future setUserID(int? userID) async {
    if (userID == null) {
      await _preferences?.remove(_keyUserID);
    } else {
      await _preferences?.setInt(_keyUserID, userID);
    }
  }

  static int? getUserID() => _preferences?.getInt(_keyUserID);

  // Add theme preference methods
  static Future setDarkMode(bool isDarkMode) async =>
      await _preferences?.setBool(_keyIsDarkMode, isDarkMode);

  static bool isDarkMode() => _preferences?.getBool(_keyIsDarkMode) ?? false;
}
