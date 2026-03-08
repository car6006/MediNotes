import '../../domain/entities/onboarding_form.dart';

class OnboardingFormApiModel {
  const OnboardingFormApiModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.version,
    this.clinicId,
    this.description,
    this.fields = const [],
    this.isActive = true,
  });

  final String id;
  final String? clinicId;
  final String title;
  final String slug;
  final String version;
  final String? description;
  final List<OnboardingFormField> fields;
  final bool isActive;

  OnboardingForm toEntity() {
    return OnboardingForm(
      id: id,
      clinicId: clinicId,
      title: title,
      slug: slug,
      version: version,
      description: description,
      fields: fields,
      isActive: isActive,
    );
  }

  factory OnboardingFormApiModel.fromJson(Map<String, dynamic> json) {
    final schema = _map(json['schema']);
    final rawFields = schema['fields'] ?? schema['questions'] ?? json['fields'];

    return OnboardingFormApiModel(
      id: (json['id'] ?? '').toString(),
      clinicId: json['clinic_id'] as String?,
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      version: (json['version'] ?? '1.0').toString(),
      description: json['description'] as String?,
      fields: _fields(rawFields),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

List<OnboardingFormField> _fields(Object? value) {
  if (value is! List) {
    return const <OnboardingFormField>[];
  }

  return value.whereType<Map>().map((item) {
    final map = Map<String, dynamic>.from(item);
    return OnboardingFormField(
      key: (map['key'] ?? map['name'] ?? '').toString(),
      label: (map['label'] ?? map['name'] ?? '').toString(),
      type: (map['type'] ?? 'text').toString(),
      required: map['required'] as bool? ?? false,
      placeholder: map['placeholder'] as String?,
      helperText: map['helper_text'] as String? ?? map['help'] as String?,
      options: _strings(map['options']),
    );
  }).where((field) => field.key.trim().isNotEmpty).toList();
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return const <String, dynamic>{};
}

List<String> _strings(Object? value) {
  if (value is! List) {
    return const <String>[];
  }

  return value.map((item) => item.toString()).toList();
}
