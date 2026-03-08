import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../controllers/consents_controller.dart';

class PatientConsentHistoryRouteArgs {
  const PatientConsentHistoryRouteArgs({
    required this.patientId,
    this.patientName,
  });

  final String patientId;
  final String? patientName;
}

class PatientConsentHistoryScreen extends ConsumerStatefulWidget {
  const PatientConsentHistoryScreen({
    super.key,
    required this.patientId,
    this.patientName,
  });

  final String patientId;
  final String? patientName;

  @override
  ConsumerState<PatientConsentHistoryScreen> createState() => _PatientConsentHistoryScreenState();
}

class _PatientConsentHistoryScreenState extends ConsumerState<PatientConsentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(consentsControllerProvider.notifier).load(widget.patientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final consentsState = ref.watch(consentsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patientName?.trim().isNotEmpty == true
              ? 'Consent history · ${widget.patientName}'
              : 'Patient consent history',
        ),
      ),
      body: consentsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (state) {
          if (state.history.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No patient consents have been captured yet.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.history.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final consent = state.history[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        consent.templateTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Version ${consent.templateVersion} · ${DateFormat('dd MMM yyyy · HH:mm').format(consent.acceptedAt.toLocal())}',
                      ),
                      const SizedBox(height: 6),
                      Text('Accepted by: ${consent.acceptedBy}'),
                      Text('Source: ${consent.sourceChannel}'),
                      if (consent.notes?.trim().isNotEmpty ?? false) ...[
                        const SizedBox(height: 8),
                        Text(consent.notes!),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
