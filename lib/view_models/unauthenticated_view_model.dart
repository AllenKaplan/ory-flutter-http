import 'package:flutter/material.dart';
import 'package:ory_flutter/services/auth_service.dart';
import 'package:ory_flutter/storage.dart';

class UnauthenticatedViewModel with ChangeNotifier {
  final AuthService _authService;
  final SecureStorage secureStorage;

  UnauthenticatedViewModel()
      : _authService = AuthService(),
        secureStorage = SecureStorage();

  Future<void> signIn(
      {required String username, required String password}) async {
    late String flowId;

    try {
      await _authService.initiateLoginFlow().then((value) => flowId = value);
    } catch (e) {
      rethrow;
    }

    try {
      final resp = await _authService.signIn(flowId, username, password);
      String token = resp.sessionToken!;
      await secureStorage.persistToken(token);
      debugPrint('token saved: ${await secureStorage.getToken()}',
          wrapWidth: 1024);
    } catch (e) {
      rethrow;
    }
    notifyListeners();
  }

  Future<void> signUp(
      {required String username,
      required String password,
      required String phone,
      required String email}) async {
    late String flowId;

    try {
      await _authService
          .initiateRegistrationFlow()
          .then((value) => flowId = value);
    } catch (e) {
      rethrow;
    }

    try {
      final resp =
          await _authService.signUp(flowId, email, password, phone, username);
      await secureStorage.persistToken(resp.sessionToken!);
      debugPrint('token: ${await secureStorage.getToken()}');
    } catch (e) {
      rethrow;
    }
    notifyListeners();
  }
}