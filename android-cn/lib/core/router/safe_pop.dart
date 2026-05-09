import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Safe go-back: tries Navigator.pop first (works across ShellRoute
/// boundaries), falls back to GoRouter.pop, then /home.
void safePop(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
  } else if (context.canPop()) {
    context.pop();
  } else {
    context.go('/home');
  }
}
