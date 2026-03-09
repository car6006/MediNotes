import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/encounter_templates_controller.dart';

class TemplatePickerRouteArgs {
  const TemplatePickerRouteArgs({
    this.clinicId,
    this.selectedTemplateId,
  });

  final String? clinicId;
  final String? selectedTemplateId;
}

class TemplatePickerScreen extends ConsumerStatefulWidget {
  const TemplatePickerScreen({
    super.key,
    this.clinicId,
    this.selectedTemplateId,
  });

  final String? clinicId;
  final String? selectedTemplateId;

  @override
  ConsumerState<TemplatePickerScreen> createState() => _TemplatePickerScreenState();
}

class _TemplatePickerScreenState extends ConsumerState<TemplatePickerScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(encounterTemplatesProvider(widget.clinicId));
    final query = _searchController.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Choose encounter template')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Search by title or specialty',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          Expanded(
            child: templatesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(error.toString(), textAlign: TextAlign.center),
                ),
              ),
              data: (templates) {
                final filtered = templates.where((template) {
                  if (query.isEmpty) {
                    return true;
                  }

                  return template.title.toLowerCase().contains(query) ||
                      (template.specialty ?? '').toLowerCase().contains(query) ||
                      (template.noteFormat ?? '').toLowerCase().contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No encounter templates matched the current filter.'),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final template = filtered[index];
                    final selected = template.id == widget.selectedTemplateId;

                    return Card(
                      child: ListTile(
                        onTap: () => Navigator.of(context).pop(template),
                        title: Text(template.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (template.specialty?.trim().isNotEmpty ?? false)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(template.specialty!),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Chip(
                                    label: Text(template.noteFormat?.toUpperCase() ?? 'SOAP'),
                                  ),
                                  Chip(
                                    label: Text('${template.encounterSections.length} sections'),
                                  ),
                                  if (template.version?.trim().isNotEmpty ?? false)
                                    Chip(label: Text('v${template.version}')),
                                ],
                              ),
                            ),
                          ],
                        ),
                        trailing: selected
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}