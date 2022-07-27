import 'package:flutter/material.dart';
import 'package:ory_flutter/screens/home.dart';
import 'package:ory_flutter/services/auth_service.dart';
import 'package:ory_flutter/view_models/authenticated_view_model.dart';
import 'package:ory_flutter/view_models/unauthenticated_view_model.dart';
import 'package:provider/provider.dart';

enum LoginState { signIn, signUp }

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  _SignIn createState() => _SignIn();
}

class _SignIn extends State<SignIn> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  LoginState state = LoginState.signIn;

  bool enableButton = true;

  onSignInError(Exception e) {
    String text = '';
    if (e is InvalidCredentialsException) {
      debugPrint('handling invalid credentials exception');
      debugPrint('check your identifier and password combo');
      text = 'Incorrect account or password';
    } else if (e is UnknownException) {
      debugPrint('handling unknown error exception');
      text = 'An error occurred';
    } else {
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
        title: const Text('Sign In/Up'),
      ),
      body: Consumer<UnauthenticatedViewModel>(
        builder: (context, vm, _) {
          signIn() {
            enableButton = false;
            vm
                .signIn(
                    username: usernameController.text,
                    password: passwordController.text)
                .then((value) => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => AuthenticatedViewModel(),
                        child: const Home(),
                      ),
                    )))
                .catchError((e) => onSignInError(e));
            enableButton = true;
          }

          signUp() {
            vm
                .signUp(
                    username: usernameController.text,
                    password: passwordController.text,
                    email: emailController.text,
                    phone: phoneController.text)
                .then((value) => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => AuthenticatedViewModel(),
                        child: const Home(),
                      ),
                    )));
          }

          return Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  controller: usernameController,
                  textInputAction: TextInputAction.next,
                ),
                TextField(
                  controller: passwordController,
                  textInputAction: TextInputAction.done,
                ),
                state == LoginState.signUp
                    ? TextField(
                        controller: phoneController,
                        textInputAction: TextInputAction.next,
                      )
                    : Container(),
                state == LoginState.signUp
                    ? TextField(
                        controller: emailController,
                        textInputAction: TextInputAction.done,
                      )
                    : Container(),
                ElevatedButton(
                    onPressed: !enableButton
                        ? null
                        : state == LoginState.signIn
                            ? signIn
                            : signUp,
                    child: state == LoginState.signIn
                        ? const Text('Sign In')
                        : const Text('Sign Up')),
                ElevatedButton(
                    onPressed: () => {
                          state == LoginState.signIn
                              ? setState(() {
                                  state = LoginState.signUp;
                                })
                              : setState(() {
                                  state = LoginState.signIn;
                                })
                        },
                    child: state == LoginState.signIn
                        ? const Text('No account? Sign Up!')
                        : const Text('Already have an account? Sign In')),
              ],
            ),
          );
        },
      ),
    );
  }
}
