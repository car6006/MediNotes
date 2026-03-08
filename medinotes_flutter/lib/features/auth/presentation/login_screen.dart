import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/login_page.dart';
import '../../../app/router.dart';
import '../../../app/session_controller.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);

    session.whenData((value) {
      if (value == null) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigator = Navigator.of(context);

        if (!navigator.mounted) {
          return;
        }

        navigator.pushNamedAndRemoveUntil(AppRouter.workspace, (route) => false);
      });
    });

    return const LoginPage();
  }
}
