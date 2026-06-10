import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<bool> isNsfwBlockingEnabled() async => _prefs.getBool('nsfw_blocking_enabled') ?? false;
  static Future<void> setNsfwBlockingEnabled(bool v) async => await _prefs.setBool('nsfw_blocking_enabled', v);

  static Future<double> blockingSensitivity() async => _prefs.getDouble('blocking_sensitivity') ?? 0.75;
  static Future<void> setBlockingSensitivity(double v) async => await _prefs.setDouble('blocking_sensitivity', v);

  static Future<bool> isOnboardingComplete() async => _prefs.getBool('onboarding_complete') ?? false;
  static Future<void> setOnboardingComplete(bool v) async => await _prefs.setBool('onboarding_complete', v);

  static Future<bool> isPremium() async => _prefs.getBool('is_premium') ?? false;
  static Future<void> setPremium(bool v) async => await _prefs.setBool('is_premium', v);
}
