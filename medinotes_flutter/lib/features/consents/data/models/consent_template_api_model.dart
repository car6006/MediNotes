import '../../domain/entities/consent_template.dart';

class ConsentTemplateApiModel {
  const ConsentTemplateApiModel({
    required this.id,
    required this.clinicId,
    required this.title,
    required this.slug,
    required this.consentType,
    required this.body,
    required this.version,
    this.description,
    this.isActive = true,
  });

  final String id;
  final String clinicId;
  final String title;
  final String slug;
  final String consentType;
  final String? description;
  final String body;
  final String version;
  final bool isActive;

  ConsentTemplate toEntity() {
    return ConsentTemplate(
      id: id,
      clinicId: clinicId,
      title: title,
      slug: slug,
      consentType: consentType,
      description: description,
      body: body,
      version: version,
      isActive: isActive,
    );
  }

  factory ConsentTemplateApiModel.fromJson(Map<String, dynamic> json) {
    return ConsentTemplateApiModel(
      id: (json['id'] ?? '').toString(),
      clinicId: (json['clinic_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      consentType: (json['consent_type'] ?? 'general').toString(),
      description: json['description'] as String?,
      body: (json['body'] ?? '').toString(),
      version: (json['version'] ?? '1.0').toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
