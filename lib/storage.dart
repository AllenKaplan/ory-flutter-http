import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ory_flutter/services/auth_service.dart';

class SecureStorage {
  static SecureStorage? _instance;

  factory SecureStorage() =>
      _instance ?? SecureStorage._(const FlutterSecureStorage());

  SecureStorage._(this._storage);

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'SESSION_TOKEN';
  static const _userKey = 'USER_ID';
  static const _emailKey = 'EMAIL';
  static const _phoneKey = 'PHONE';
  static const _usernameKey = 'USERNAME';

  Future<void> persistToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<bool> hasToken() async {
    var value = await _storage.read(key: _tokenKey);
    return value != null;
  }

  Future<void> deleteToken() async {
    return _storage.delete(key: _tokenKey);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> persistUserId(String uuid) async {
    await _storage.write(key: _userKey, value: uuid);
  }

  Future<bool> hasUserId() async {
    var value = await _storage.read(key: _userKey);
    return value != null;
  }

  Future<void> deleteUserId() async {
    return _storage.delete(key: _userKey);
  }

  Future<String?> getUserId() async {
    return _storage.read(key: _userKey);
  }

  Future<void> persistTraits(Traits traits) async {
    await _storage.write(key: _emailKey, value: traits.email);
    await _storage.write(key: _phoneKey, value: traits.phone);
    await _storage.write(key: _usernameKey, value: traits.username);
  }

  Future<bool> hasTraits() async {
    var value = await _storage.read(key: _usernameKey);
    return value != null;
  }

  Future<void> deleteTraits() async {
    _storage.delete(key: _emailKey);
    _storage.delete(key: _phoneKey);
    _storage.delete(key: _usernameKey);
    return;
  }

  Future<Traits?> getTraits() async {
    final email = await _storage.read(key: _emailKey);
    final phone = await _storage.read(key: _phoneKey);
    final username = await _storage.read(key: _usernameKey);
    return Traits(email: email, username: username, phone: phone);
  }
}
