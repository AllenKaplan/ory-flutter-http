import 'package:flutter/material.dart';
import 'package:ory_flutter/services/auth_service.dart';
import 'package:ory_flutter/storage.dart';

class UnauthenticatedViewModel with ChangeNotifier {
  final AuthService _authService;
  final SecureStorage secureStorage;

  UnauthenticatedViewModel()
      : _authService = AuthService(),
        secureStorage = SecureStorage();

  Future<void> login(
      {required String username, required String password}) async {
    late String flowId;

    try {
      flowId = await _authService.initiateLoginFlow();
    } catch (e) {
      debugPrint('caught initiate login error in view model... $e');
      rethrow;
    }

    try {
      final resp = await _authService.login(flowId, username, password);
      String token = resp.sessionToken!;
      await secureStorage.persistToken(token);
      await secureStorage.persistUserId(resp.userId!);
      await secureStorage.persistTraits(resp.traits!);
      debugPrint('token saved: ${await secureStorage.getToken()}',
          wrapWidth: 1024);
    } on Exception catch (e) {
      debugPrint('caught login error in view model... $e');
      rethrow;
    }
    notifyListeners();
  }

  Future<void> register(
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
          await _authService.register(flowId, username, email, phone, password);
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

  Future<void> recoverAccount(String email) async {
    late String flowId;

    try {
      await _authService.initiateRecoveryFlow().then((value) => flowId = value);
    } catch (e) {
      rethrow;
    }

    await _authService.recoverAccount(flowId, email);
  }
}
