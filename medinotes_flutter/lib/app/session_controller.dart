import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controller.dart';
import 'models.dart';
import 'repository.dart';

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, AuthSession?>(
      SessionController.new,
    );

class SessionController extends AsyncNotifier<AuthSession?> {
  late final ClinicRepository _repository;

  @override
  Future<AuthSession?> build() async {
    _repository = ref.read(clinicRepositoryProvider);

    try {
      final restored = await _repository.restoreSession();
      if (restored == null) {
        return null;
      }

      return _repository.refreshSession(restored);
    } catch (_) {
      return null;
    }
  }

  Future<void> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    final previous = state.valueOrNull;
    state = const AsyncLoading();

    try {
      final session = await _repository.login(
        email: email,
        password: password,
        deviceName: deviceName,
      );
      final refreshed = await _repository.refreshSession(session);
      state = AsyncValue.data(refreshed);
    } catch (error, stackTrace) {
      state = AsyncValue.data(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}
