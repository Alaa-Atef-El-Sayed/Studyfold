import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static late SharedPreferences _prefs;

  static const String _keyDesktopView = 'desktopViewEnabled';
  // static const String _keyThemeMode = 'appThemeMode';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get desktopViewValue {
    return _prefs.getBool(_keyDesktopView) ?? false;
  }

  // String get themeMode {
  //   return _prefs.getString(_keyThemeMode) ?? 'light';
  // }




  Future<bool> setDesktopView(bool isEnabled) async {
    return await _prefs.setBool(_keyDesktopView, isEnabled);
  }

  // Future<bool> setThemeMode(String mode) async {
  //   return await _prefs.getString(_keyThemeMode, mode);
  // }
}
