import 'package:shared_preferences/shared_preferences.dart';

class GenrePreferences {
  GenrePreferences({this.preferences});

  final SharedPreferencesAsync? preferences;
  late final SharedPreferencesAsync _storage =
      preferences ?? SharedPreferencesAsync();
  static const key = 'last_selected_genres';
  static const sortKey = 'last_movie_sort';

  Future<String?> loadSort() => _storage.getString(sortKey);

  Future<void> saveSort(String sort) => _storage.setString(sortKey, sort);

  Future<List<String>> load() async =>
      await _storage.getStringList(key) ?? <String>[];

  Future<void> save(List<String> genres) async {
    await _storage.setStringList(key, genres);
  }
}
