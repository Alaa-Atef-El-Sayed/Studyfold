import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static late SharedPreferences _prefs;

  static const String _keyDesktopView = 'desktopViewEnabled';
  static const String _keyDesktopViewScale = 'desktopViewScale';
  // static const String _keyThemeMode = 'appThemeMode';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get desktopViewValue {
    return _prefs.getBool(_keyDesktopView) ?? false;
  }

  double get desktopViewScale {
    return _prefs.getDouble(_keyDesktopViewScale) ?? 1;
  }

  // String get themeMode {
  //   return _prefs.getString(_keyThemeMode) ?? 'light';
  // }

  Future<bool> setDesktopView(bool isEnabled) async {
    return await _prefs.setBool(_keyDesktopView, isEnabled);
  }

  Future<bool> setDesktopViewScale(double value) async {
    return await _prefs.setDouble(_keyDesktopViewScale, value);
  }

  // Future<bool> setThemeMode(String mode) async {
  //   return await _prefs.getString(_keyThemeMode, mode);
  // }
}
