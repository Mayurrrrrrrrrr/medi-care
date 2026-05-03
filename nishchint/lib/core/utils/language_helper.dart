import '../../shared/providers/settings_provider.dart';

String t(String keyEn, String keyHi) {
  try {
    final language = SettingsProvider.instance.language;
    return language == 'hi' ? keyHi : keyEn;
  } catch (e) {
    return keyEn;
  }
}
