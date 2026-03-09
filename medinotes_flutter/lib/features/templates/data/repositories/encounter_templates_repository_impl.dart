import '../../domain/entities/encounter_template.dart';
import '../../domain/repositories/encounter_templates_repository.dart';
import '../datasources/encounter_templates_remote_data_source.dart';

class EncounterTemplatesRepositoryImpl implements EncounterTemplatesRepository {
  EncounterTemplatesRepositoryImpl({
    EncounterTemplatesRemoteDataSource? remoteDataSource,
  }) : _remote = remoteDataSource ?? EncounterTemplatesRemoteDataSource();

  final EncounterTemplatesRemoteDataSource _remote;

  @override
  Future<List<EncounterTemplate>> loadTemplates({
    String? clinicId,
    String? specialty,
    bool activeOnly = true,
  }) {
    return _remote.fetchTemplates(
      clinicId: clinicId,
      specialty: specialty,
      activeOnly: activeOnly,
    );
  }

  @override
  Future<EncounterTemplate?> loadTemplate(String templateId) async {
    try {
      return await _remote.fetchTemplate(templateId);
    } catch (_) {
      return null;
    }
  }
}