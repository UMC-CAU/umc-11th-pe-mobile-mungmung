import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> readAccessToken();
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _tokenKey = 'movielog.access_token';
  static const _installKey = 'movielog.install_initialized';

  final _storage = const FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  );
  final SharedPreferencesAsync _preferences;
  Future<void>? _initializing;

  Future<void> _prepare() => _initializing ??= _prepareInstall();

  Future<void> _prepareInstall() async {
    try {
      if (await _preferences.getBool(_installKey) == true) return;
      await _storage.deleteAll();
      await _preferences.setBool(_installKey, true);
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  @override
  Future<String?> readAccessToken() async {
    await _prepare();
    return _storage.read(key: _tokenKey);
  }

  @override
  Future<void> saveAccessToken(String token) async {
    await _prepare();
    await _storage.write(key: _tokenKey, value: token);
  }

  @override
  Future<void> clear() => _storage.delete(key: _tokenKey);
}
