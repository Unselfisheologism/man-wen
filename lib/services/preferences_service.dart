import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<bool> isOnboardingComplete() async => _prefs.getBool('onboarding_complete') ?? false;
  static Future<void> setOnboardingComplete(bool v) async => await _prefs.setBool('onboarding_complete', v);

  static Future<bool> isPremium() async => _prefs.getBool('is_premium') ?? false;
  static Future<void> setPremium(bool v) async => await _prefs.setBool('is_premium', v);
}
