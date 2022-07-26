import 'package:flutter/material.dart';
import 'package:ory_flutter/services/auth_service.dart';
import 'package:ory_flutter/storage.dart';

class AuthenticatedViewModel with ChangeNotifier {
  final AuthService _authService;
  final SecureStorage secureStorage;

  AuthenticatedViewModel()
      : _authService = AuthService(),
        secureStorage = SecureStorage();

  void signOut() {
    _authService.signOut().then((value) => secureStorage.deleteToken());
  }

  Future<String?> getToken() async {
    return secureStorage.getToken();
  }
}
