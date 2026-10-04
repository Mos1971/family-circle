import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Back button that always does something: it goes back if there is a
/// previous screen, and otherwise returns to Home. (Reloading the app or
/// opening it from a home-screen icon leaves nothing to go back to, which
/// previously made a plain pop() a dead button.)
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BackButton(
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
    );
  }
}
