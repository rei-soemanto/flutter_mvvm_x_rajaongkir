import 'package:shared_preferences/shared_preferences.dart';

/// Stores small strings on the device.
///
/// The history repository and the region cache both write JSON through this
/// interface, and tests swap in an in-memory implementation.
abstract interface class KeyValueStorageService {
  /// Reads the value stored under [key], or null when there is none.
  Future<String?> readString(String key);

  /// Writes [value] under [key].
  Future<void> writeString(String key, String value);

  /// Removes whatever is stored under [key].
  Future<void> remove(String key);
}

/// A [KeyValueStorageService] backed by `shared_preferences`.
class SharedPreferencesStorageService implements KeyValueStorageService {
  SharedPreferencesStorageService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readString(String key) => _preferences.getString(key);

  @override
  Future<void> writeString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);
}
