import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/appointments/presentation/screens/appointment_form_screen.dart';
import '../features/appointments/presentation/screens/appointment_list_screen.dart';
import '../features/consents/presentation/screens/consent_capture_screen.dart';
import '../features/consents/presentation/screens/patient_consent_history_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_shell.dart';
import '../features/onboarding/presentation/screens/onboarding_form_screen.dart';
import '../features/patients/presentation/screens/patient_detail_screen.dart';
import '../features/patients/presentation/screens/patient_form_screen.dart';
import '../features/patients/presentation/screens/patient_list_screen.dart';
import 'session_controller.dart';

class AppRouter {
  static const root = '/';
  static const login = '/login';
  static const workspace = '/workspace';
  static const patientRegistry = '/patients';
  static const patientDetail = '/patients/detail';
  static const patientForm = '/patients/form';
  static const appointmentList = '/appointments';
  static const appointmentForm = '/appointments/form';
  static const onboardingForm = '/onboarding/form';
  static const consentCapture = '/consents/capture';
  static const consentHistory = '/consents/history';

  static final navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case workspace:
        return MaterialPageRoute<void>(
          builder: (_) => const DashboardShell(),
          settings: settings,
        );
      case patientRegistry:
        return MaterialPageRoute<void>(
          builder: (_) => const PatientListScreen(),
          settings: settings,
        );
      case patientDetail:
        final args = settings.arguments;
        if (args is! PatientDetailRouteArgs || args.patientId.trim().isEmpty) {
          return MaterialPageRoute<void>(
            builder: (_) => const _MissingRouteArgumentPage(
              title: 'Patient detail unavailable',
              message: 'A patient selection is required before opening the detail screen.',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute<void>(
          builder: (_) => PatientDetailScreen(patientId: args.patientId),
          settings: settings,
        );
      case patientForm:
        final args = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => PatientFormScreen(
            patient: args is PatientFormRouteArgs ? args.patient : null,
          ),
          settings: settings,
        );
      case appointmentList:
        final args = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => AppointmentListScreen(
            patientId: args is AppointmentListRouteArgs ? args.patientId : null,
            patientName: args is AppointmentListRouteArgs ? args.patientName : null,
          ),
          settings: settings,
        );
      case appointmentForm:
        final args = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => AppointmentFormScreen(
            appointment: args is AppointmentFormRouteArgs ? args.appointment : null,
            patientId: args is AppointmentFormRouteArgs ? args.patientId : null,
            patientName: args is AppointmentFormRouteArgs ? args.patientName : null,
          ),
          settings: settings,
        );
      case onboardingForm:
        final args = settings.arguments;
        if (args is! OnboardingFormRouteArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => const _MissingRouteArgumentPage(
              title: 'Onboarding unavailable',
              message: 'A patient selection is required before opening onboarding.',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute<void>(
          builder: (_) => OnboardingFormScreen(
            patientId: args.patientId,
            patientName: args.patientName,
            appointmentId: args.appointmentId,
          ),
          settings: settings,
        );
      case consentCapture:
        final args = settings.arguments;
        if (args is! ConsentCaptureRouteArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => const _MissingRouteArgumentPage(
              title: 'Consent unavailable',
              message: 'A patient selection is required before opening consent capture.',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute<void>(
          builder: (_) => ConsentCaptureScreen(
            patientId: args.patientId,
            patientName: args.patientName,
            appointmentId: args.appointmentId,
          ),
          settings: settings,
        );
      case consentHistory:
        final args = settings.arguments;
        if (args is! PatientConsentHistoryRouteArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => const _MissingRouteArgumentPage(
              title: 'Consent history unavailable',
              message: 'A patient selection is required before opening consent history.',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute<void>(
          builder: (_) => PatientConsentHistoryScreen(
            patientId: args.patientId,
            patientName: args.patientName,
          ),
          settings: settings,
        );
      case root:
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const _SessionLandingPage(),
          settings: settings,
        );
    }
  }
}

class _SessionLandingPage extends ConsumerWidget {
  const _SessionLandingPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);

    session.whenData((value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final targetRoute = value == null ? AppRouter.login : AppRouter.workspace;
        final navigator = Navigator.of(context);

        if (!navigator.mounted) {
          return;
        }

        navigator.pushNamedAndRemoveUntil(targetRoute, (route) => false);
      });
    });

    if (session.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigator = Navigator.of(context);

        if (!navigator.mounted) {
          return;
        }

        navigator.pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
      });
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _MissingRouteArgumentPage extends StatelessWidget {
  const _MissingRouteArgumentPage({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
