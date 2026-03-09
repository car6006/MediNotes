import '../entities/encounter_template.dart';

abstract class EncounterTemplatesRepository {
  Future<List<EncounterTemplate>> loadTemplates({
    String? clinicId,
    String? specialty,
    bool activeOnly = true,
  });

  Future<EncounterTemplate?> loadTemplate(String templateId);
}