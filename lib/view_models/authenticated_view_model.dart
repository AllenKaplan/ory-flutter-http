import 'package:flutter/material.dart';
import 'package:ory_flutter/services/auth_service.dart';
import 'package:ory_flutter/storage.dart';

class AuthenticatedViewModel with ChangeNotifier {
  final AuthService _authService;
  final SecureStorage secureStorage;

  AuthenticatedViewModel()
      : _authService = AuthService(),
        secureStorage = SecureStorage();

  void logout() {
    _authService.logout().then((value) => secureStorage.deleteToken());
  }

  Future<String?> getToken() async {
    return secureStorage.getToken();
  }

  Future<String?> getUuid() async {
    return secureStorage.getUserId();
  }

  Future<Traits?> getTraits() async {
    return secureStorage.getTraits();
  }

  Future<UserSession> getUser() async {
    return UserSession(
        sessionToken: await getToken(),
        userId: await getUuid(),
        traits: await getTraits());
  }

  Future<void> changeAccountSettings(
      {required String password, username, email, phone}) async {
    late String flowId;
    final traits = Traits(email: email, username: username, phone: phone);

    try {
      await _authService.initiateSettingsFlow().then((value) => flowId = value);
    } catch (e) {
      rethrow;
    }

    try {
      final user =
          await _authService.changeAccountProfile(flowId, password, traits);
      if (user.traits != null) await secureStorage.persistTraits(user.traits!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changeAccountPassword(String password, newPassword) async {
    late String flowId;

    try {
      await _authService.initiateSettingsFlow().then((value) => flowId = value);
    } catch (e) {
      rethrow;
    }

    try {
      final resp = await _authService.changeAccountPassword(
          flowId, password, newPassword);
      String token = resp.sessionToken!;
      await secureStorage.persistToken(token);
      await secureStorage.persistUserId(resp.userId!);
      await secureStorage.persistTraits(resp.traits!);
      debugPrint('token: ${await secureStorage.getToken()}');
    } catch (e) {
      rethrow;
    }
    notifyListeners();
  }
}
