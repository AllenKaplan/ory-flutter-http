import 'package:flutter/material.dart';
import 'package:ory_flutter/screens/home.dart';
import 'package:ory_flutter/services/auth_service.dart';
import 'package:ory_flutter/view_models/authenticated_view_model.dart';
import 'package:ory_flutter/view_models/unauthenticated_view_model.dart';
import 'package:provider/provider.dart';

import 'account_recovery.dart';

enum LoginFormState { login, register }

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  LoginFormState state = LoginFormState.login;

  bool enableButton = true;

  onError(Exception e) {
    String text = '';
    if (e is InvalidCredentialsException) {
      debugPrint('handling invalid credentials exception');
      debugPrint('check your identifier and password combo');
      text = 'Incorrect account or password';
    } else if (e is UnknownException) {
      debugPrint('handling unknown error exception');
      text = 'An error occurred';
    } else {
      debugPrint('exception occurred with no further details! $e');
      text = 'An error occurred';
      throw e;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    enableButton = true;

    return Scaffold(
      appBar: AppBar(
        title: state == LoginFormState.login
            ? const Text('Sign In')
            : const Text('Sign Up'),
      ),
      body: Consumer<UnauthenticatedViewModel>(
        builder: (context, vm, _) {
          login() {
            debugPrint('login submitted');
            enableButton = false;
            vm
                .login(
                    username: usernameController.text,
                    password: passwordController.text)
                .then(
                  (value) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => AuthenticatedViewModel(),
                        child: const Home(),
                      ),
                    ),
                  ),
                )
                .catchError(
                  (e) => onError(e),
                );
            enableButton = true;
          }

          register() {
            vm
                .register(
                    username: usernameController.text,
                    password: passwordController.text,
                    email: emailController.text,
                    phone: phoneController.text)
                .then(
                  (value) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => AuthenticatedViewModel(),
                        child: const Home(),
                      ),
                    ),
                  ),
                )
                .catchError(
                  (e) => onError(e),
                );
          }

          bool isValidEmail(String str) {
            return RegExp(
                    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
                .hasMatch(str);
          }

          bool isValidPhone(String str) {
            return RegExp(r'^(\+\d{1,3}-\(\d{3}\)-\d{3}-\d{4})$').hasMatch(str);
          }

          validateEmail(value) {
            if (state == LoginFormState.login) return null;
            if (!isValidEmail(value)) return 'invalid email';
          }

          validateUsername(value) {
            if (value == null || value == "") return 'username cannot be empty';
          }

          validatePhone(value) {
            if (state == LoginFormState.login) return null;
            if (!isValidPhone(value)) return 'invalid phone';
          }

          validatePassword(value) {
            if (value == null || value == "") return 'password cannot be empty';
            if (value.length < 8) {
              return 'password must be at least 8 characters';
            }
          }

          return Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    validator: validateUsername,
                    decoration: const InputDecoration(
                      hintText: 'Username*',
                    ),
                    controller: usernameController,
                    textInputAction: TextInputAction.next,
                  ),
                  TextFormField(
                    validator: validatePassword,
                    decoration: const InputDecoration(
                      hintText: 'Password*',
                    ),
                    controller: passwordController,
                    textInputAction: TextInputAction.next,
                  ),
                  state == LoginFormState.register
                      ? TextFormField(
                          validator: validatePhone,
                          decoration: const InputDecoration(
                            hintText: 'Phone*',
                          ),
                          controller: phoneController,
                          textInputAction: TextInputAction.next,
                        )
                      : Container(),
                  state == LoginFormState.register
                      ? TextFormField(
                          validator: validateEmail,
                          decoration: const InputDecoration(
                            hintText: 'Email*',
                          ),
                          controller: emailController,
                          textInputAction: TextInputAction.next,
                        )
                      : Container(),
                  ElevatedButton(
                      onPressed: () {
                        debugPrint('sign in/up button pressed');
                        // if (formKey.currentState!.validate()) {
                        debugPrint('validated');
                        formKey.currentState!.validate()
                            ? (state == LoginFormState.login
                                ? login()
                                : register())
                            : null;
                      },
                      child: state == LoginFormState.login
                          ? const Text('Sign In')
                          : const Text('Sign Up')),
                  ElevatedButton(
                      onPressed: () => {
                            state == LoginFormState.login
                                ? setState(() {
                                    state = LoginFormState.register;
                                  })
                                : setState(() {
                                    state = LoginFormState.login;
                                  })
                          },
                      child: state == LoginFormState.login
                          ? const Text('No account? Sign Up!')
                          : const Text('Already have an account? Sign In')),
                  ElevatedButton(
                      onPressed: () => {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ChangeNotifierProvider(
                                      create: (_) => UnauthenticatedViewModel(),
                                      child: const AccountRecovery(),
                                    )))
                          },
                      child: const Text('Forgot your password?')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
