import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../domain/entities/encounter.dart';
import '../controllers/encounters_controller.dart';
import 'encounter_detail_screen.dart';
import 'start_encounter_screen.dart';

class EncounterListRouteArgs {
  const EncounterListRouteArgs({
    this.patientId,
    this.patientName,
    this.appointmentId,
  });

  final String? patientId;
  final String? patientName;
  final String? appointmentId;
}

class EncounterListScreen extends ConsumerStatefulWidget {
  const EncounterListScreen({
    super.key,
    this.patientId,
    this.patientName,
    this.appointmentId,
  });

  final String? patientId;
  final String? patientName;
  final String? appointmentId;

  @override
  ConsumerState<EncounterListScreen> createState() => _EncounterListScreenState();
}

class _EncounterListScreenState extends ConsumerState<EncounterListScreen> {
  static const _statuses = <String?>[
    null,
    'created',
    'in_progress',
    'dictation_captured',
    'transcription_pending',
    'draft_note_ready',
    'doctor_review_pending',
    'signed_off',
    'completed',
  ];

  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(encountersControllerProvider.notifier).load(
            patientId: widget.patientId,
            patientName: widget.patientName,
            appointmentId: widget.appointmentId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final encountersAsync = ref.watch(encountersControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patientId?.trim().isNotEmpty == true
              ? 'Encounters · ${widget.patientName ?? 'Patient'}'
              : 'Encounter worklist',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh encounters',
            onPressed: () => ref.read(encountersControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openStartEncounter,
        icon: const Icon(Icons.playlist_add_check_circle_outlined),
        label: const Text('Start encounter'),
      ),
      body: encountersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _EncounterErrorState(
          message: error.toString(),
          onRetry: () => ref.read(encountersControllerProvider.notifier).refresh(),
        ),
        data: (state) => Column(
          children: [
            if (state.isLoadingList) const LinearProgressIndicator(),
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DropdownButton<String?>(
                          value: _statusFilter,
                          hint: const Text('Any status'),
                          items: _statuses
                              .map(
                                (status) => DropdownMenuItem<String?>(
                                  value: status,
                                  child: Text(
                                    status == null ? 'Any status' : _statusTitle(status),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) async {
                            setState(() => _statusFilter = value);
                            await ref.read(encountersControllerProvider.notifier).load(
                                  patientId: widget.patientId,
                                  patientName: widget.patientName,
                                  appointmentId: widget.appointmentId,
                                  status: value,
                                );
                          },
                        ),
                        if (state.message?.trim().isNotEmpty ?? false)
                          Text(state.message!),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: state.encounters.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No encounters matched the current filters.'),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: state.encounters.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final encounter = state.encounters[index];

                        return _EncounterCard(
                          encounter: encounter,
                          onOpen: () => _openEncounter(encounter.id),
                          onContinue: encounter.isCompleted
                              ? null
                              : () => _openEncounter(encounter.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStartEncounter() async {
    await Navigator.of(context)
        .pushNamed(
          AppRouter.startEncounter,
          arguments: StartEncounterRouteArgs(
            patientId: widget.patientId,
            patientName: widget.patientName,
            appointmentId: widget.appointmentId,
          ),
        )
        .then((_) => ref.read(encountersControllerProvider.notifier).refresh());
  }

  Future<void> _openEncounter(String encounterId) async {
    await Navigator.of(context)
        .pushNamed(
          AppRouter.encounterDetail,
          arguments: EncounterDetailRouteArgs(
            encounterId: encounterId,
            patientName: widget.patientName,
          ),
        )
        .then((_) => ref.read(encountersControllerProvider.notifier).refresh());
  }

  String _statusTitle(String value) {
    return value
        .split('_')
        .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _EncounterCard extends StatelessWidget {
  const _EncounterCard({
    required this.encounter,
    required this.onOpen,
    this.onContinue,
  });

  final Encounter encounter;
  final VoidCallback onOpen;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final startedAt = encounter.timeline.startedAt ?? encounter.createdAt;
    final startedLabel = startedAt == null
        ? 'Awaiting start time'
        : DateFormat('EEE, dd MMM yyyy · HH:mm').format(startedAt.toLocal());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        encounter.patient?.fullName ?? encounter.patient?.preferredName ?? encounter.patientId,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(startedLabel),
                    ],
                  ),
                ),
                Chip(label: Text(_statusTitle(encounter.status))),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (encounter.chiefComplaint?.trim().isNotEmpty ?? false)
                  Chip(label: Text(encounter.chiefComplaint!)),
                if (encounter.template?.title?.trim().isNotEmpty ?? false)
                  Chip(
                    avatar: const Icon(Icons.description_outlined, size: 18),
                    label: Text(encounter.template!.title!),
                  ),
                Chip(
                  avatar: const Icon(Icons.mic_none, size: 18),
                  label: Text('${encounter.counts.audioFiles} audio'),
                ),
                Chip(
                  avatar: const Icon(Icons.subtitles_outlined, size: 18),
                  label: Text('${encounter.counts.transcripts} transcripts'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (encounter.currentClinicalNote != null)
              Text(
                'Current note: ${_statusTitle(encounter.currentClinicalNote!.status)} · version ${encounter.currentClinicalNote!.currentVersionNumber}',
              ),
            if (encounter.provider?.fullName?.trim().isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Provider: ${encounter.provider!.fullName}'),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Open'),
                ),
                if (onContinue != null)
                  OutlinedButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.arrow_forward_outlined),
                    label: const Text('Continue'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusTitle(String value) {
    return value
        .split('_')
        .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _EncounterErrorState extends StatelessWidget {
  const _EncounterErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}