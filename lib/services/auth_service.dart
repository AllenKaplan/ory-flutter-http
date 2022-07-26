import 'package:ory_client/api.dart';
import 'package:ory_flutter/storage.dart';

class Traits {
  final String email, phone, username;

  Traits({required this.email, required this.username, required this.phone});
}

class AuthService {
  final backendURL = const String.fromEnvironment('BACKEND');
  final kratosClient = V0alpha2Api(
      ApiClient(basePath: const String.fromEnvironment('KRATOS_API')));

  Future<String> initiateRegistrationFlow() async {
    try {
      var response = await kratosClient
          .initializeSelfServiceRegistrationFlowWithoutBrowser();
      return response!.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> initiateLoginFlow() async {
    try {
      var response =
          await kratosClient.initializeSelfServiceLoginFlowWithoutBrowser();
      return response!.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<SuccessfulSelfServiceLoginWithoutBrowser> signIn(
      String flowId, String identifier, String password) async {
    const method = "password";
    final body = SubmitSelfServiceLoginFlowWithPasswordMethodBody(
      identifier: identifier,
      method: method,
      password: password,
    );
    try {
      final response =
          await kratosClient.submitSelfServiceLoginFlow(flowId, body);
      return response!;
    } catch (e) {
      rethrow;
    }
  }

  Future<SuccessfulSelfServiceRegistrationWithoutBrowser> signUp(String flowId,
      String email, String password, String phone, String username) async {
    const method = "password";
    final traits = Traits(email: email, username: username, phone: phone);
    var body = SubmitSelfServiceRegistrationFlowBody(
        method: method, password: password, provider: '', traits: traits);
    try {
      var response =
          await kratosClient.submitSelfServiceRegistrationFlow(flowId, body);
      return response!;
    } catch (e) {
      rethrow;
    }
  }

  Future<Session> getCurrentSession(String token) async {
    try {
      var response = await kratosClient.toSession(xSessionToken: token);
      return response!;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    final SecureStorage storage = SecureStorage();
    final String? sessionToken = await storage.getToken();
    if (sessionToken != null) {
      final body = SubmitSelfServiceLogoutFlowWithoutBrowserBody(
          sessionToken: sessionToken);
      try {
        final response =
            await kratosClient.submitSelfServiceLogoutFlowWithoutBrowser(body);
        return;
      } catch (e) {
        rethrow;
      }
    }
  }
}
