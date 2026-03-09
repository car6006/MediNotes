import 'package:dio/dio.dart';

import '../../../../app/repository.dart';
import '../../../../shared/json_parsing.dart';
import '../../domain/entities/encounter_template.dart';

class EncounterTemplatesRemoteDataSource {
  EncounterTemplatesRemoteDataSource({SessionLocalStore? sessionStore})
    : _sessionStore = sessionStore ?? SessionLocalStore();

  final SessionLocalStore _sessionStore;

  Future<List<EncounterTemplate>> fetchTemplates({
    String? clinicId,
    String? specialty,
    bool activeOnly = true,
  }) async {
    final dio = await _authorizedClient();
    final response = await dio.get<Map<String, dynamic>>(
      '/encounter-templates',
      queryParameters: {
        if (clinicId?.trim().isNotEmpty ?? false) 'clinic_id': clinicId,
        if (specialty?.trim().isNotEmpty ?? false) 'specialty': specialty,
        'active': activeOnly,
      },
    );

    return asListOfMaps(response.data?['data'])
        .map(EncounterTemplate.fromJson)
        .toList();
  }

  Future<EncounterTemplate> fetchTemplate(String templateId) async {
    final dio = await _authorizedClient();
    final response = await dio.get<Map<String, dynamic>>(
      '/encounter-templates/$templateId',
    );

    return EncounterTemplate.fromJson(asMap(response.data?['data']));
  }

  Future<Dio> _authorizedClient() async {
    final session = await _sessionStore.load();
    if (session == null || session.token.trim().isEmpty) {
      throw const ClinicAuthException(
        'Sign in is required before encounter templates can sync.',
      );
    }

    return Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.token}',
        },
      ),
    );
  }
}