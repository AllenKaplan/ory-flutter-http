import 'dart:convert';

import "package:http/http.dart" as http;
import 'package:ory_flutter/storage.dart';

class Traits {
  final String email, phone, username;

  Traits({required this.email, required this.username, required this.phone});
}

class UnauthorizedException implements Exception {} // session token is invalid

class InvalidCredentialsException implements Exception {
  // invalid credentials when sign in/sign up
  final Map<String, String> errors;

  InvalidCredentialsException(this.errors);
}

class UnknownException implements Exception {
  //unknown exceptions
  final String message;

  UnknownException(this.message);
}

class AuthService {
  final backendURL = const String.fromEnvironment('BACKEND');
  final kratosURL = const String.fromEnvironment('KRATOS_API');

  Future<String> initiateRegistrationFlow() async {
    var response =
        await http.get(Uri.parse("$kratosURL/self-service/registration/api"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["id"]; //return registration flow id
    } else if (response.statusCode == 400 || response.statusCode == 500) {
      final data = jsonDecode(response.body);
      final error = data["error"];
      throw UnknownException(error["message"]);
    } else {
      throw Exception();
    }
  }

  Future<String> initiateLoginFlow() async {
    var response = await http
        .get(Uri.parse("$kratosURL/self-service/login/api?refresh=true"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["id"]; //return login flow id
    } else if (response.statusCode == 400 || response.statusCode == 500) {
      final data = jsonDecode(response.body);
      final error = data["error"];
      throw UnknownException(error["message"]);
    } else {
      throw Exception();
    }
  }

  Future<String> signIn(String flowId, String email, String password) async {
    var response = await http.post(
        Uri.parse("$kratosURL/self-service/login?flow=$flowId"),
        headers: <String, String>{"Content-Type": "application/json"},
        body: jsonEncode(<String, String>{
          "method": "password",
          "password": password,
          "password_identifier": email
        }));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String sessionToken = data["session_token"];
      return sessionToken;
    } else if (response.statusCode == 400) {
      final data = jsonDecode(response.body);
      final errors = checkForErrors(data);
      throw InvalidCredentialsException(errors);
    } else if (response.statusCode == 500) {
      final data = jsonDecode(response.body);
      final error = data["error"];
      throw UnknownException(error["message"]);
    } else if (response.statusCode == 422) {
      final data = jsonDecode(response.body);
      final error = data["message"];
      throw UnknownException(error);
    } else {
      throw Exception();
    }
  }

  Future<String> signUp(
      String flowId, String username, email, phone, password) async {
    final response = await http.post(
        Uri.parse("$kratosURL/self-service/registration?flow=$flowId"),
        headers: <String, String>{"Content-Type": "application/json"},
        body: jsonEncode(<String, String>{
          "method": "password",
          "password": password,
          "traits.email": email
        }));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String sessionToken = data["session_token"];
      return sessionToken;
    } else if (response.statusCode == 400) {
      final data = json.decode(response.body);

      final errors = checkForErrors(data);

      throw InvalidCredentialsException(errors);
    } else if (response.statusCode == 500) {
      final data = jsonDecode(response.body);
      final error = data["error"];
      throw UnknownException(error["message"]);
    } else if (response.statusCode == 422) {
      final data = jsonDecode(response.body);
      final error = data["message"];
      throw UnknownException(error);
    } else {
      throw Exception();
    }
  }

  Future<Map<String, dynamic>> getCurrentSession(String token) async {
    final response = await http.get(
      Uri.parse("$backendURL/whoami"),
      headers: <String, String>{
        "Accept": "application/json",
        "Session_token": token
      },
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      return Map<String, dynamic>.from(userData["oryUser"]);
    } else if (response.statusCode == 401) {
      throw UnauthorizedException();
    } else if (response.statusCode == 403 || response.statusCode == 500) {
      final data = jsonDecode(response.body);
      final error = data["error"];
      throw UnknownException(error["message"]);
    } else {
      throw Exception();
    }
  }

  Future<void> signOut() async {
    final SecureStorage storage = SecureStorage();
    final String? sessionToken = await storage.getToken();
    if (sessionToken != null) {
      final response = await http.delete(
          Uri.parse("$kratosURL/self-service/logout/api"),
          headers: <String, String>{"Content-Type": "application/json"},
          body: jsonEncode(<String, String>{"session_token": sessionToken}));

      if (response.statusCode == 204) {
        //revocation successful
        await storage.deleteToken();
      } else if (response.statusCode == 400 || response.statusCode == 500) {
        final data = jsonDecode(response.body);
        final error = data["error"];
        throw UnknownException(error["message"]);
      } else {
        throw Exception();
      }
    }
  }

  Map<String, String> checkForErrors(Map<String, dynamic> response) {
    //for errors see https://www.ory.sh/kratos/docs/reference/api#operation/initializeSelfServiceLoginFlowWithoutBrowser
    final ui = Map<String, dynamic>.from(response["ui"]);
    final list = ui["nodes"];
    final generalErrors = ui["messages"];

    Map errors = <String, String>{};
    for (var i = 0; i < list.length; i++) {
      //check if there are any input errors
      final entry = Map<String, dynamic>.from(list[i]);
      if ((entry["messages"] as List).isNotEmpty) {
        final String name = entry["attributes"]["name"];
        final message = entry["messages"][0] as Map<String, dynamic>;
        errors.putIfAbsent(name, () => message["text"] as String);
      }
    }

    if (generalErrors != null) {
      //check if there is a general error
      final message = (generalErrors as List)[0] as Map<String, dynamic>;
      errors.putIfAbsent("general", () => message["text"] as String);
    }

    return errors as Map<String, String>;
  }
}
