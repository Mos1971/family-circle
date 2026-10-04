import 'package:flutter/material.dart';

/// Lets code outside the widget tree (e.g. repositories) show a snackbar.
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showAppMessage(String message) {
  appMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
