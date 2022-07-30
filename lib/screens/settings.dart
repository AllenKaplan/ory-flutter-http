import 'package:flutter/material.dart';
import 'package:ory_flutter/services/auth_service.dart';
import 'package:ory_flutter/view_models/authenticated_view_model.dart';
import 'package:provider/provider.dart';

enum LoginState { login, register }

class Settings extends StatefulWidget {
  final UserSession user;
  const Settings({Key? key, required this.user}) : super(key: key);

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<AuthenticatedViewModel>(
        builder: (context, vm, _) {
          TextEditingController usernameController =
              TextEditingController(text: widget.user.traits?.username);
          TextEditingController phoneController =
              TextEditingController(text: widget.user.traits?.phone);
          TextEditingController emailController =
              TextEditingController(text: widget.user.traits?.email);
          TextEditingController newPasswordController = TextEditingController();
          TextEditingController passwordController = TextEditingController();
          final profileFormKey = GlobalKey<FormState>();
          final passwordFormKey = GlobalKey<FormState>();

          bool isValidEmail(String str) {
            return RegExp(
                    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
                .hasMatch(str);
          }

          bool isValidPhone(String str) {
            return RegExp(r'^(\+\d{1,3}-\(\d{3}\)-\d{3}-\d{4})$').hasMatch(str);
          }

          validateEmail(value) {
            if (!isValidEmail(value)) return 'invalid email';
          }

          validateUsername(value) {
            if (value == null || value == "") return 'username cannot be empty';
          }

          validatePhone(value) {
            if (!isValidPhone(value)) return 'invalid phone';
          }

          validatePassword(value) {
            if (value == null || value == "") return 'password cannot be empty';
            if (value.length < 8) {
              return 'password must be at least 8 characters';
            }
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Form(
                    key: profileFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          validator: validateUsername,
                          decoration:
                              const InputDecoration(hintText: 'Username*'),
                          controller: usernameController,
                          textInputAction: TextInputAction.next,
                        ),
                        TextFormField(
                          validator: validatePhone,
                          decoration: const InputDecoration(hintText: 'Phone*'),
                          controller: phoneController,
                          textInputAction: TextInputAction.next,
                        ),
                        TextFormField(
                          validator: validateEmail,
                          decoration: const InputDecoration(hintText: 'Email*'),
                          controller: emailController,
                          textInputAction: TextInputAction.next,
                        ),
                        TextFormField(
                          validator: validatePassword,
                          decoration: const InputDecoration(
                              hintText: 'Current Password*'),
                          controller: passwordController,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              profileFormKey.currentState!.validate()
                                  ? vm.changeAccountSettings(
                                      email: emailController.text,
                                      username: usernameController.text,
                                      phone: phoneController.text,
                                      password: passwordController.text,
                                    )
                                  : null,
                          child: const Text('Edit Account'),
                        ),
                      ],
                    )),
                const Divider(
                  thickness: 1,
                ),
                Form(
                  key: passwordFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        validator: validatePassword,
                        decoration:
                            const InputDecoration(hintText: 'New Password*'),
                        controller: newPasswordController,
                        textInputAction: TextInputAction.next,
                      ),
                      TextFormField(
                        validator: validatePassword,
                        decoration: const InputDecoration(
                            hintText: 'Current Password*'),
                        controller: passwordController,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      ElevatedButton(
                          onPressed: () =>
                              passwordFormKey.currentState!.validate()
                                  ? vm.changeAccountPassword(
                                      passwordController.text,
                                      newPasswordController.text)
                                  : null,
                          child: const Text('Edit Password')),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
