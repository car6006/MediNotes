import '../../../../shared/json_parsing.dart';

class EncounterTemplate {
  const EncounterTemplate({
    required this.id,
    required this.title,
    required this.templateBody,
    this.clinicId,
    this.slug,
    this.version,
    this.specialty,
    this.noteFormat,
    this.instructions,
    this.sections = const <String>[],
    this.encounterSections = const <EncounterTemplateSection>[],
    this.isSystem = false,
    this.isActive = true,
    this.clinicName,
    this.clinicSlug,
    this.authorName,
    this.authorEmail,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? clinicId;
  final String title;
  final String? slug;
  final String? version;
  final String? specialty;
  final String? noteFormat;
  final String templateBody;
  final String? instructions;
  final List<String> sections;
  final List<EncounterTemplateSection> encounterSections;
  final bool isSystem;
  final bool isActive;
  final String? clinicName;
  final String? clinicSlug;
  final String? authorName;
  final String? authorEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory EncounterTemplate.fromJson(Map<String, dynamic> json) {
    final clinic = asMap(json['clinic']);
    final author = asMap(json['author']);

    return EncounterTemplate(
      id: parseString(json['id']),
      clinicId: parseNullableString(json['clinic_id']),
      title: parseString(json['title']),
      slug: parseNullableString(json['slug']),
      version: parseNullableString(json['version']),
      specialty: parseNullableString(json['specialty']),
      noteFormat: parseNullableString(json['note_format']),
      templateBody: parseString(json['template_body']),
      instructions: parseNullableString(json['instructions']),
      sections: asStringList(json['sections']),
      encounterSections: asListOfMaps(json['encounter_sections'])
          .map(EncounterTemplateSection.fromJson)
          .toList(),
      isSystem: parseBool(json['is_system']),
      isActive: parseBool(json['is_active'], fallback: true),
      clinicName: parseNullableString(clinic['name']),
      clinicSlug: parseNullableString(clinic['slug']),
      authorName: parseNullableString(author['name']),
      authorEmail: parseNullableString(author['email']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}

class EncounterTemplateSection {
  const EncounterTemplateSection({
    required this.key,
    required this.label,
    required this.position,
    this.id,
    this.prompt,
    this.isRequired = false,
    this.defaultContent,
    this.meta = const <String, dynamic>{},
  });

  final String? id;
  final String key;
  final String label;
  final int position;
  final String? prompt;
  final bool isRequired;
  final String? defaultContent;
  final Map<String, dynamic> meta;

  factory EncounterTemplateSection.fromJson(Map<String, dynamic> json) {
    return EncounterTemplateSection(
      id: parseNullableString(json['id']),
      key: parseString(json['key']),
      label: parseString(
        json['label'],
        fallback: parseString(json['key'], fallback: 'Section'),
      ),
      position: parseInt(json['position'], fallback: 1),
      prompt: parseNullableString(json['prompt']),
      isRequired: parseBool(json['is_required']),
      defaultContent: parseNullableString(
        json['default_content'] ?? json['content'],
      ),
      meta: asMap(json['meta']),
    );
  }
}