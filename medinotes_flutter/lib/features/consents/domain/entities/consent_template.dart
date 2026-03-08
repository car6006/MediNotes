class ConsentTemplate {
  const ConsentTemplate({
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
}
