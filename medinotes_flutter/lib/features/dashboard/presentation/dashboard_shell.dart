import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/clinic_shell.dart';
import '../../../app/router.dart';
import '../../../app/session_controller.dart';

class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);

    if (session.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (session.hasError || session.valueOrNull == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigator = Navigator.of(context);

        if (!navigator.mounted) {
          return;
        }

        navigator.pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
      });

      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const ClinicShell();
  }
}
