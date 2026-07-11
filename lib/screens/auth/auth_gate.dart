import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';
import 'login_screen.dart';

/// Swaps between Login and the post-login home based on [AuthProvider]
/// state, so logging in/out never needs an explicit Navigator push/pop —
/// the two screens are just different builds of the same widget.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return authProvider.isLoggedIn ? const DashboardScreen() : const LoginScreen();
  }
}
