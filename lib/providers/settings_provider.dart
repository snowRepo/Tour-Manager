import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../constants/app_constants.dart';

class SettingsProvider extends ChangeNotifier {
  final DbHelper _db = DbHelper();

  Map<String, String> _settings = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  Map<String, String> get settings => Map.unmodifiable(_settings);

  String get businessName => _settings[SettingKeys.businessName] ?? '';
  String get businessPhone => _settings[SettingKeys.businessPhone] ?? '';
  String get businessEmail => _settings[SettingKeys.businessEmail] ?? '';
  String get businessLogo => _settings[SettingKeys.businessLogo] ?? '';
  String get termsAndConditions =>
      _settings[SettingKeys.termsAndConditions] ?? AppStrings.defaultTnC;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    _settings = await _db.getAllSettings();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSetting(String key, String value) async {
    await _db.setSetting(key, value);
    _settings[key] = value;
    notifyListeners();
  }

  Future<void> updateBusinessName(String v) =>
      updateSetting(SettingKeys.businessName, v);
  Future<void> updateBusinessPhone(String v) =>
      updateSetting(SettingKeys.businessPhone, v);
  Future<void> updateBusinessEmail(String v) =>
      updateSetting(SettingKeys.businessEmail, v);
  Future<void> updateBusinessLogo(String v) =>
      updateSetting(SettingKeys.businessLogo, v);
  Future<void> updateTermsAndConditions(String v) =>
      updateSetting(SettingKeys.termsAndConditions, v);
}
