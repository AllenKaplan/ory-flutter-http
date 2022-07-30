import 'package:flutter/material.dart';
import 'package:ory_flutter/screens/settings.dart';
import 'package:ory_flutter/screens/sign_in.dart';
import 'package:ory_flutter/services/auth_service.dart';
import 'package:ory_flutter/view_models/authenticated_view_model.dart';
import 'package:ory_flutter/view_models/unauthenticated_view_model.dart';
import 'package:provider/provider.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticatedViewModel>(builder: (context, vm, _) {
      void logout() {
        vm.logout();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) => UnauthenticatedViewModel(),
              child: const Login(),
            ),
          ),
          (route) => false,
        );
      }

      return Scaffold(
          body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: FutureBuilder(
            future: vm.getUser(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.connectionState != ConnectionState.done ||
                    snapshot.data == null) {
                  return Center(
                      child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('back')));
                } else {
                  final user = snapshot.data as UserSession;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'UserID: ${user.userId}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        'Traits: ${user.traits}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        'Token: ${user.sessionToken}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                        onPressed: () => logout(),
                        child: const Text('Sign Out'),
                      ),
                      ElevatedButton(
                        onPressed: () => {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChangeNotifierProvider(
                                create: (_) => AuthenticatedViewModel(),
                                child: Settings(user: user),
                              ),
                            ),
                          )
                        },
                        child: const Text('Settings'),
                      )
                    ],
                  );
                }
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }),
      ));
    });
  }
}
