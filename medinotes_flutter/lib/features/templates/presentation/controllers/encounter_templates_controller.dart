import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/encounter_templates_repository_impl.dart';
import '../../domain/entities/encounter_template.dart';
import '../../domain/repositories/encounter_templates_repository.dart';

final encounterTemplatesRepositoryProvider = Provider<EncounterTemplatesRepository>((ref) {
  return EncounterTemplatesRepositoryImpl();
});

final encounterTemplatesProvider = FutureProvider.family<List<EncounterTemplate>, String?>((ref, clinicId) {
  return ref.read(encounterTemplatesRepositoryProvider).loadTemplates(clinicId: clinicId);
});

final encounterTemplateProvider = FutureProvider.family<EncounterTemplate?, String>((ref, templateId) {
  return ref.read(encounterTemplatesRepositoryProvider).loadTemplate(templateId);
});