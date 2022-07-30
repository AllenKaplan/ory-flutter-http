import 'package:flutter/material.dart';
import 'package:ory_flutter/view_models/unauthenticated_view_model.dart';
import 'package:provider/provider.dart';

class AccountRecovery extends StatefulWidget {
  const AccountRecovery({Key? key}) : super(key: key);

  @override
  AccountRecoveryState createState() => AccountRecoveryState();
}

class AccountRecoveryState extends State<AccountRecovery> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<UnauthenticatedViewModel>(
        builder: (context, vm, _) {
          final formKey = GlobalKey<FormState>();
          final emailController = TextEditingController();

          bool isValidEmail(String str) {
            return RegExp(
                    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
                .hasMatch(str);
          }

          validateEmail(value) {
            if (value == null || value.isEmpty || !isValidEmail(value)) {
              return 'invalid email';
            }
            return null;
          }

          return Form(
              key: formKey,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        hintText: 'Email*',
                      ),
                      validator: validateEmail,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Recovery Sent!')),
                          );
                          vm.recoverAccount(emailController.text);
                          Navigator.of(context).pop();
                        } else {}
                      },
                      child: const Text('Submit'),
                    ),
                    ElevatedButton(
                      onPressed: () async => {Navigator.of(context).maybePop()},
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ));
        },
      ),
    );
  }

  handleError(e, s) {
    debugPrint('error caught in account recovery! $e');
  }
}
