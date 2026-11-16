import 'package:shared_preferences/shared_preferences.dart';

class RememberedEmail {
  static const _key = 'movielog.remembered_email';
  late final _preferences = SharedPreferencesAsync();

  Future<String?> read() => _preferences.getString(_key);

  Future<void> save(String? email) async {
    if (email == null) {
      await _preferences.remove(_key);
    } else {
      await _preferences.setString(_key, email);
    }
  }
}
