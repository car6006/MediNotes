class OnboardingFormField {
  const OnboardingFormField({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.placeholder,
    this.options = const [],
    this.helperText,
  });

  final String key;
  final String label;
  final String type;
  final bool required;
  final String? placeholder;
  final List<String> options;
  final String? helperText;
}

class OnboardingForm {
  const OnboardingForm({
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
}
