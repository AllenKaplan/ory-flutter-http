import 'package:flutter/material.dart';
import 'package:ory_flutter/screens/sign_in.dart';
import 'package:ory_flutter/view_models/authenticated_view_model.dart';
import 'package:ory_flutter/view_models/unauthenticated_view_model.dart';
import 'package:provider/provider.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticatedViewModel>(builder: (context, vm, _) {
      void signOut() {
        vm.signOut();
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
                  create: (_) => UnauthenticatedViewModel(),
                  child: const SignIn(),
                )));
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: FutureBuilder(
            future: vm.getToken(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.connectionState != ConnectionState.done ||
                    snapshot.data == null) {
                  return Center(
                      child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('back')));
                } else {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${snapshot.data}'),
                      ElevatedButton(
                        onPressed: () => signOut(),
                        child: const Text('Sign Out'),
                      )
                    ],
                  );
                }
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }),
      );
    });
  }
}
