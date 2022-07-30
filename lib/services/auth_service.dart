import 'dart:convert';

import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'package:ory_flutter/storage.dart';

class AuthService {
  final kratosURL = const String.fromEnvironment('KRATOS_API');
  final SecureStorage secureStorage;

  AuthService() : secureStorage = SecureStorage();

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

  Future<UserSession> login(
      String flowId, String email, String password) async {
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
      return jsonResponseToUserSession(data);
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

  Future<UserSession> register(
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
      return jsonResponseToUserSession(data);
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
      Uri.parse("$kratosURL/whoami"),
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

  Future<void> logout() async {
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

  Future<String> initiateSettingsFlow() async {
    final token = await secureStorage.getToken();

    var response = await http.get(
      Uri.parse("$kratosURL/self-service/settings/api"),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Accept": 'application/json',
        'Authorization': 'Bearer $token'
      },
    );
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

  Future<UserSession> changeAccountProfile(
      String flowId, password, Traits traits) async {
    final token = await secureStorage.getToken();

    var traitsList = <String, String>{};
    traitsList["username"] = traits.username!;
    traitsList["email"] = traits.email!;
    traitsList["phone"] = traits.phone!;

    var response = await http.post(
        Uri.parse("$kratosURL/self-service/settings?flow=$flowId"),
        headers: <String, String>{
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(<String, dynamic>{
          "method": "profile",
          "traits": traitsList,
        }));

    if (response.statusCode == 200) {
      debugPrint('changeAccountProfile success!');
      final data = jsonDecode(response.body);
      return jsonResponseToUserSession(data);
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

  Future<UserSession> changeAccountPassword(
      String flowId, password, newPassword) async {
    final token = await secureStorage.getToken();

    var response = await http.post(
        Uri.parse("$kratosURL/self-service/settings?flow=$flowId"),
        headers: <String, String>{
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(<String, dynamic>{
          "method": "password",
          "traits": newPassword,
        }));

    if (response.statusCode == 200) {
      debugPrint('changeAccountPassword success!');
      final data = jsonDecode(response.body);
      return jsonResponseToUserSession(data);
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

  Future<String> initiateRecoveryFlow() async {
    var response =
        await http.get(Uri.parse("$kratosURL/self-service/recovery/api"));
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

  recoverAccount(String flowId, String email) async {
    var response = await http.post(
        Uri.parse("$kratosURL/self-service/recovery?flow=$flowId"),
        headers: <String, String>{
          "Content-Type": "application/json",
          'Accept': 'application/json'
        },
        body: jsonEncode(<String, dynamic>{
          "method": "link",
          "email": email,
        }));

    if (response.statusCode == 200) {
      debugPrint('recoverAccount success!');
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

  UserSession jsonResponseToUserSession(data) {
    final String? sessionToken = data["session_token"];
    final String? userId = data["session"]["identity"]["id"];
    final String? email = data["session"]["identity"]["traits"]["email"];
    final String? phone = data["session"]["identity"]["traits"]["phone"];
    final String? username = data["session"]["identity"]["traits"]["username"];
    final traits = Traits(email: email, phone: phone, username: username);
    return UserSession(
        sessionToken: sessionToken, userId: userId, traits: traits);
  }
}

class UserSession {
  final String? sessionToken, userId;
  final Traits? traits;
  UserSession(
      {required this.sessionToken, required this.userId, required this.traits});
}

class Traits {
  final String? email, phone, username;

  Traits({required this.email, required this.username, required this.phone});

  @override
  String toString() {
    return 'Traits{email: $email, phone: $phone, username: $username}';
  }
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
