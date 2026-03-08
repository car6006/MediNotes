import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'MEDINOTES_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  static const deviceName = String.fromEnvironment(
    'MEDINOTES_DEVICE_NAME',
    defaultValue: 'MediNotes Flutter Client',
  );
}

class ClinicAuthException implements Exception {
  const ClinicAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ClinicLocalStore {
  ClinicLocalStore({FlutterSecureStorage? secureStorage, AesGcm? cipher})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
      _cipher = cipher ?? AesGcm.with256bits();

  static const _encryptedStateKey = 'medinotes.encrypted_state';
  static const _keyEncryptionKey = 'medinotes.encrypted_state_key';
  static const _patientsKey = 'medinotes.patients';
  static const _visitsKey = 'medinotes.visits';
  static const _templatesKey = 'medinotes.templates';
  static const _dictationsKey = 'medinotes.dictations';
  static const _queueKey = 'medinotes.queue';
  static const _lastSyncedKey = 'medinotes.last_synced';
  static const _syncMessageKey = 'medinotes.sync_message';

  final FlutterSecureStorage _secureStorage;
  final AesGcm _cipher;

  Future<ClinicState> load() async {
    final prefs = await SharedPreferences.getInstance();

    final encryptedState = prefs.getString(_encryptedStateKey);
    if (encryptedState != null && encryptedState.isNotEmpty) {
      final decrypted = await _decryptState(encryptedState);
      if (decrypted != null) {
        return decrypted;
      }
    }

    final legacyState = ClinicState(
      patients: _decodeLegacyList(
        prefs.getString(_patientsKey),
        PatientRecord.fromJson,
      ),
      visits: _decodeLegacyList(
        prefs.getString(_visitsKey),
        VisitRecord.fromJson,
      ),
      templates: _decodeLegacyList(
        prefs.getString(_templatesKey),
        NoteTemplateRecord.fromJson,
      ),
      dictations: _decodeLegacyList(
        prefs.getString(_dictationsKey),
        DictationCapture.fromJson,
      ),
      queue: _decodeLegacyList(prefs.getString(_queueKey), SyncTask.fromJson),
      lastSyncedAt: DateTime.tryParse(prefs.getString(_lastSyncedKey) ?? ''),
      syncMessage: prefs.getString(_syncMessageKey),
    );

    if (_hasLegacyData(legacyState)) {
      await save(legacyState);
      await _clearLegacyKeys(prefs);
      return legacyState;
    }

    return const ClinicState();
  }

  Future<void> save(ClinicState state) async {
    final prefs = await SharedPreferences.getInstance();

    final payload = await _encryptState(state);
    await prefs.setString(_encryptedStateKey, payload);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_encryptedStateKey);
    await _clearLegacyKeys(prefs);
    await _secureStorage.delete(key: _keyEncryptionKey);
  }

  Future<String> _encryptState(ClinicState state) async {
    final secretKey = await _secretKey();
    final nonce = _cipher.newNonce();
    final secretBox = await _cipher.encrypt(
      utf8.encode(jsonEncode(state.toJson())),
      secretKey: secretKey,
      nonce: nonce,
    );

    return jsonEncode({
      'nonce': base64Encode(secretBox.nonce),
      'cipher_text': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    });
  }

  Future<ClinicState?> _decryptState(String payload) async {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final nonce = decoded['nonce'];
      final cipherText = decoded['cipher_text'];
      final mac = decoded['mac'];
      if (nonce is! String || cipherText is! String || mac is! String) {
        return null;
      }

      final secretKey = await _secretKey();
      final secretBox = SecretBox(
        base64Decode(cipherText),
        nonce: base64Decode(nonce),
        mac: Mac(base64Decode(mac)),
      );
      final clearBytes = await _cipher.decrypt(secretBox, secretKey: secretKey);
      final clearText = utf8.decode(clearBytes);
      final stateJson = jsonDecode(clearText);
      if (stateJson is! Map<String, dynamic>) {
        return null;
      }

      return ClinicState.fromJson(stateJson);
    } catch (_) {
      return null;
    }
  }

  Future<SecretKey> _secretKey() async {
    final rawKey = await _secureStorage.read(key: _keyEncryptionKey);
    if (rawKey != null && rawKey.isNotEmpty) {
      return SecretKey(base64Decode(rawKey));
    }

    final key = await _cipher.newSecretKey();
    final keyBytes = await key.extractBytes();
    await _secureStorage.write(
      key: _keyEncryptionKey,
      value: base64Encode(keyBytes),
    );
    return SecretKey(keyBytes);
  }

  bool _hasLegacyData(ClinicState state) {
    return state.patients.isNotEmpty ||
        state.visits.isNotEmpty ||
        state.templates.isNotEmpty ||
        state.dictations.isNotEmpty ||
        state.queue.isNotEmpty ||
        state.lastSyncedAt != null ||
        (state.syncMessage?.isNotEmpty ?? false);
  }

  Future<void> _clearLegacyKeys(SharedPreferences prefs) async {
    await prefs.remove(_patientsKey);
    await prefs.remove(_visitsKey);
    await prefs.remove(_templatesKey);
    await prefs.remove(_dictationsKey);
    await prefs.remove(_queueKey);
    await prefs.remove(_lastSyncedKey);
    await prefs.remove(_syncMessageKey);
  }

  List<T> _decodeLegacyList<T>(
    String? raw,
    T Function(Map<String, dynamic> json) builder,
  ) {
    if (raw == null || raw.isEmpty) {
      return <T>[];
    }

    try {
      final data = jsonDecode(raw) as List<dynamic>;
      return data
          .whereType<Map>()
          .map((item) => builder(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return <T>[];
    }
  }
}

class SessionLocalStore {
  SessionLocalStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _sessionKey = 'medinotes.session';

  final FlutterSecureStorage _secureStorage;

  Future<AuthSession?> load() async {
    final raw = await _secureStorage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return AuthSession.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AuthSession session) {
    return _secureStorage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  Future<void> clear() => _secureStorage.delete(key: _sessionKey);
}

class ClinicApiClient {
  ClinicApiClient({String? baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

  final Dio _dio;

  void setBearerToken(String? token) {
    if (token == null || token.trim().isEmpty) {
      _dio.options.headers.remove('Authorization');
      return;
    }

    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<AuthSession> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'device_name': deviceName ?? AppConfig.deviceName,
        },
      );
      final data = _decodeMap(response.data?['data']);
      final session = AuthSession.fromJson(data);
      setBearerToken(session.token);
      return session;
    } on DioException catch (error) {
      throw ClinicAuthException(_messageFromDio(error));
    }
  }

  Future<AuthSession> fetchCurrentSession(AuthSession current) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      final data = _decodeMap(response.data?['data']);
      return AuthSession.fromJson({
        ...data,
        'token': current.token,
        'expires_at':
            data['expires_at'] ?? current.expiresAt?.toIso8601String(),
      }).copyWith(
        security: data['security'] is Map<String, dynamic>
            ? SecurityPolicy.fromJson(
                Map<String, dynamic>.from(
                  data['security'] as Map<String, dynamic>,
                ),
              )
            : current.security,
      );
    } on DioException catch (_) {
      return current;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } on DioException catch (_) {
      // Allow local logout to proceed even if the API is offline.
    }
  }

  Future<Map<String, dynamic>> fetchBootstrap() async {
    final response = await _dio.get<Map<String, dynamic>>('/bootstrap');
    return response.data ?? const <String, dynamic>{};
  }

  Future<List<PatientRecord>> searchPatients(String query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/patients',
      queryParameters: {'search': query},
    );

    return _decodeList(response.data?['data'], PatientRecord.fromJson);
  }

  Future<({PatientRecord patient, List<VisitRecord> visits})> fetchPatient(
    String patientId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/patients/$patientId',
    );
    final data = Map<String, dynamic>.from(
      (response.data?['data'] as Map?) ?? const <String, dynamic>{},
    );

    final patient = PatientRecord.fromJson(data);
    final visits = _decodeList(data['visits'], VisitRecord.fromJson);

    return (patient: patient, visits: visits);
  }

  Future<void> upsertPatient(PatientRecord patient) {
    return _dio.put<void>('/patients/${patient.id}', data: patient.toJson());
  }

  Future<void> upsertVisit(VisitRecord visit) {
    return _dio.put<void>('/visits/${visit.id}', data: visit.toJson());
  }

  Future<void> upsertTemplate(NoteTemplateRecord template) {
    return _dio.put<void>(
      '/note-templates/${template.id}',
      data: template.toJson(),
    );
  }

  Future<void> createDictation(DictationCapture dictation) {
    return _dio.post<void>(
      '/visits/${dictation.visitId}/dictations',
      data: dictation.toJson(),
    );
  }

  Map<String, dynamic> _decodeMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const <String, dynamic>{};
  }

  String _messageFromDio(DioException error) {
    final data = error.response?.data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final errors = map['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }

        return firstError.toString();
      }

      final message = map['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return error.message ?? 'Unable to complete the request.';
  }

  List<T> _decodeList<T>(
    Object? value,
    T Function(Map<String, dynamic> json) builder,
  ) {
    if (value is! List) {
      return <T>[];
    }

    return value
        .whereType<Map>()
        .map((item) => builder(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class ClinicRepository {
  ClinicRepository({
    ClinicLocalStore? localStore,
    SessionLocalStore? sessionStore,
    ClinicApiClient? apiClient,
    Uuid? uuid,
  }) : _localStore = localStore ?? ClinicLocalStore(),
       _sessionStore = sessionStore ?? SessionLocalStore(),
       _apiClient = apiClient ?? ClinicApiClient(),
       _uuid = uuid ?? const Uuid();

  final ClinicLocalStore _localStore;
  final SessionLocalStore _sessionStore;
  final ClinicApiClient _apiClient;
  final Uuid _uuid;

  Future<AuthSession?> restoreSession() async {
    final session = await _sessionStore.load();
    if (session == null || session.token.trim().isEmpty) {
      return null;
    }

    _apiClient.setBearerToken(session.token);
    return session;
  }

  Future<AuthSession> refreshSession(AuthSession session) async {
    _apiClient.setBearerToken(session.token);
    final refreshed = await _apiClient.fetchCurrentSession(session);
    await _sessionStore.save(refreshed);
    return refreshed;
  }

  Future<AuthSession> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    final session = await _apiClient.login(
      email: email,
      password: password,
      deviceName: deviceName,
    );
    await _sessionStore.save(session);
    return session;
  }

  Future<void> logout() async {
    final session = await _sessionStore.load();
    _apiClient.setBearerToken(session?.token);

    await _apiClient.logout();
    await _sessionStore.clear();
    await _localStore.clear();
    _apiClient.setBearerToken(null);
  }

  Future<ClinicState> bootstrap() async {
    var state = await _localStore.load();

    if (state.templates.isEmpty) {
      state = state.copyWith(templates: _starterTemplates);
      await _localStore.save(state);
    }

    try {
      final remote = await _apiClient.fetchBootstrap();
      state = _mergeBootstrap(state, remote).copyWith(
        lastSyncedAt: DateTime.now(),
        syncMessage: 'Bootstrap synced from API.',
      );
      await _localStore.save(state);
    } catch (_) {
      state = state.copyWith(
        syncMessage: state.queue.isEmpty
            ? 'Running from encrypted local cache. Sign in connectivity restores sync.'
            : 'Running offline with encrypted local cache and pending changes.',
      );
      await _localStore.save(state);
    }

    return state;
  }

  Future<ClinicState> searchPatients(ClinicState current, String query) async {
    if (query.trim().isEmpty) {
      return current;
    }

    try {
      final matches = await _apiClient.searchPatients(query.trim());
      final next = current.copyWith(
        patients: _mergeById(current.patients, matches, (item) => item.id),
        syncMessage: 'Patient lookup updated from API.',
      );
      await _localStore.save(next);
      return next;
    } catch (_) {
      return current.copyWith(syncMessage: 'Search used local cache only.');
    }
  }

  Future<ClinicState> loadPatientHistory(
    ClinicState current,
    String patientId,
  ) async {
    try {
      final snapshot = await _apiClient.fetchPatient(patientId);
      final next = current.copyWith(
        patients: _mergeById(current.patients, [
          snapshot.patient,
        ], (item) => item.id),
        visits: _mergeById(current.visits, snapshot.visits, (item) => item.id),
        syncMessage: 'Patient history loaded.',
      );
      await _localStore.save(next);
      return next;
    } catch (_) {
      return current.copyWith(
        syncMessage: 'Showing cached patient history only.',
      );
    }
  }

  Future<ClinicState> upsertPatient(
    ClinicState current,
    PatientRecord patient,
  ) async {
    final next = current.copyWith(
      patients: _upsert(current.patients, patient, (item) => item.id),
      queue: _enqueue(
        current.queue,
        SyncTask(
          key: 'patient:${patient.id}',
          operation: SyncOperation.upsertPatient,
          entityId: patient.id,
          payload: patient.toJson(),
          createdAt: DateTime.now(),
        ),
      ),
      syncMessage: 'Patient saved locally and queued for sync.',
    );

    await _localStore.save(next);
    return syncNow(next);
  }

  Future<ClinicState> upsertVisit(
    ClinicState current,
    VisitRecord visit,
  ) async {
    final patients = current.patients.map((patient) {
      if (patient.id != visit.patientId) {
        return patient;
      }

      return patient.copyWith(
        lastVisitAt: visit.startedAt ?? DateTime.now(),
        visitsCount: current.visitsForPatient(visit.patientId).length + 1,
      );
    }).toList();

    final next = current.copyWith(
      patients: patients,
      visits: _upsert(current.visits, visit, (item) => item.id),
      queue: _enqueue(
        current.queue,
        SyncTask(
          key: 'visit:${visit.id}',
          operation: SyncOperation.upsertVisit,
          entityId: visit.id,
          payload: visit.toJson(),
          createdAt: DateTime.now(),
        ),
      ),
      syncMessage: 'Visit saved locally and queued for sync.',
    );

    await _localStore.save(next);
    return syncNow(next);
  }

  Future<ClinicState> upsertTemplate(
    ClinicState current,
    NoteTemplateRecord template,
  ) async {
    final next = current.copyWith(
      templates: _upsert(current.templates, template, (item) => item.id),
      queue: _enqueue(
        current.queue,
        SyncTask(
          key: 'template:${template.id}',
          operation: SyncOperation.upsertTemplate,
          entityId: template.id,
          payload: template.toJson(),
          createdAt: DateTime.now(),
        ),
      ),
      syncMessage: 'Template saved locally and queued for sync.',
    );

    await _localStore.save(next);
    return syncNow(next);
  }

  Future<ClinicState> createDictation(
    ClinicState current,
    DictationCapture dictation,
  ) async {
    final visits = current.visits.map((visit) {
      if (visit.id != dictation.visitId) {
        return visit;
      }

      final transcript = [visit.transcript, dictation.transcript]
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .join('\n\n');

      return visit.copyWith(
        transcript: transcript.isEmpty ? visit.transcript : transcript,
        syncedAt: DateTime.now(),
      );
    }).toList();

    final next = current.copyWith(
      visits: visits,
      dictations: _upsert(current.dictations, dictation, (item) => item.id),
      queue: _enqueue(
        current.queue,
        SyncTask(
          key: 'dictation:${dictation.id}',
          operation: SyncOperation.createDictation,
          entityId: dictation.id,
          payload: dictation.toJson(),
          createdAt: DateTime.now(),
        ),
        replaceExisting: false,
      ),
      syncMessage: 'Offline dictation captured and queued for sync.',
    );

    await _localStore.save(next);
    return syncNow(next);
  }

  Future<ClinicState> syncNow(ClinicState current) async {
    var next = current.copyWith(
      isSyncing: true,
      syncMessage: 'Syncing queue...',
    );
    await _localStore.save(next);

    final remaining = <SyncTask>[...next.queue];

    for (final task in List<SyncTask>.from(remaining)) {
      try {
        switch (task.operation) {
          case SyncOperation.upsertPatient:
            await _apiClient.upsertPatient(
              PatientRecord.fromJson(task.payload),
            );
          case SyncOperation.upsertVisit:
            await _apiClient.upsertVisit(VisitRecord.fromJson(task.payload));
          case SyncOperation.upsertTemplate:
            await _apiClient.upsertTemplate(
              NoteTemplateRecord.fromJson(task.payload),
            );
          case SyncOperation.createDictation:
            await _apiClient.createDictation(
              DictationCapture.fromJson(task.payload),
            );
        }

        remaining.removeWhere((item) => item.key == task.key);
      } catch (error) {
        next = next.copyWith(
          queue: remaining,
          isSyncing: false,
          syncMessage: _syncErrorMessage(error),
        );
        await _localStore.save(next);
        return next;
      }
    }

    next = next.copyWith(
      queue: remaining,
      isSyncing: false,
      lastSyncedAt: DateTime.now(),
      syncMessage: 'All pending items synced.',
    );

    try {
      final remote = await _apiClient.fetchBootstrap();
      next = _mergeBootstrap(next, remote).copyWith(
        queue: remaining,
        isSyncing: false,
        lastSyncedAt: DateTime.now(),
        syncMessage: 'All pending items synced.',
      );
    } catch (_) {
      next = next.copyWith(
        syncMessage: 'Queue cleared. Remote refresh unavailable.',
      );
    }

    await _localStore.save(next);
    return next;
  }

  PatientRecord buildPatient({
    required String firstName,
    required String lastName,
    String? medicalRecordNumber,
    DateTime? dateOfBirth,
    String? sex,
    String? phone,
    String? email,
    List<String> allergies = const [],
    List<String> medications = const [],
    List<String> medicalHistory = const [],
    String? notes,
  }) {
    return PatientRecord(
      id: _uuid.v4(),
      medicalRecordNumber: medicalRecordNumber ?? _suggestMedicalRecordNumber(),
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      sex: sex,
      phone: phone,
      email: email,
      allergies: allergies,
      medications: medications,
      medicalHistory: medicalHistory,
      notes: notes,
      lastVisitAt: null,
      visitsCount: 0,
    );
  }

  String createId() => _uuid.v4();

  String _suggestMedicalRecordNumber() {
    final today = DateTime.now();
    return 'MRN-${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}-${_uuid.v4().substring(0, 4).toUpperCase()}';
  }

  ClinicState _mergeBootstrap(
    ClinicState current,
    Map<String, dynamic> payload,
  ) {
    final data = Map<String, dynamic>.from(
      (payload['data'] as Map?) ?? const <String, dynamic>{},
    );

    final patients = _decodeRemoteList(
      data['patients'],
      PatientRecord.fromJson,
    );
    final visits = _decodeRemoteList(data['visits'], VisitRecord.fromJson);
    final templates = _decodeRemoteList(
      data['templates'],
      NoteTemplateRecord.fromJson,
    );

    return current.copyWith(
      patients: _mergeById(current.patients, patients, (item) => item.id),
      visits: _mergeById(current.visits, visits, (item) => item.id),
      templates: _mergeById(current.templates, templates, (item) => item.id),
    );
  }

  List<T> _decodeRemoteList<T>(
    Object? input,
    T Function(Map<String, dynamic> json) builder,
  ) {
    if (input is! List) {
      return <T>[];
    }

    return input
        .whereType<Map>()
        .map((item) => builder(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<T> _mergeById<T>(
    List<T> original,
    List<T> incoming,
    String Function(T item) idOf,
  ) {
    var merged = [...original];
    for (final item in incoming) {
      merged = _upsert(merged, item, idOf);
    }
    return merged;
  }

  List<T> _upsert<T>(List<T> items, T item, String Function(T item) idOf) {
    final next = [...items];
    final index = next.indexWhere((entry) => idOf(entry) == idOf(item));
    if (index == -1) {
      next.add(item);
    } else {
      next[index] = item;
    }
    return next;
  }

  List<SyncTask> _enqueue(
    List<SyncTask> queue,
    SyncTask task, {
    bool replaceExisting = true,
  }) {
    final next = [...queue];
    if (replaceExisting) {
      next.removeWhere((entry) => entry.key == task.key);
    }
    next.add(task);
    next.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return next;
  }

  String _syncErrorMessage(Object error) {
    if (error is ClinicAuthException) {
      return error.message;
    }

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return 'Session needs re-authentication before sync can continue. Local cache stays encrypted on device.';
      }

      return 'Offline mode active: ${error.message ?? 'Unable to reach API.'}';
    }

    return 'Offline mode active. Changes remain queued locally.';
  }

  List<NoteTemplateRecord> get _starterTemplates => const [
    NoteTemplateRecord(
      id: '11111111-1111-4111-8111-111111111111',
      title: 'General Clinic SOAP',
      specialty: 'Primary Care',
      templateBody:
          'Subjective\n- Presenting complaint\n- Relevant history\n\nObjective\n- Exam\n- Observations\n\nAssessment\n- Impression\n\nPlan\n- Treatment\n- Follow-up',
      sections: ['Subjective', 'Objective', 'Assessment', 'Plan'],
      isSystem: true,
    ),
    NoteTemplateRecord(
      id: '22222222-2222-4222-8222-222222222222',
      title: 'Chronic Disease Review',
      specialty: 'Medical Follow-up',
      templateBody:
          'Problem list\nMedication adherence\nRecent results\nRisk discussion\nUpdated plan',
      sections: [
        'Problem list',
        'Medication adherence',
        'Recent results',
        'Risk discussion',
        'Updated plan',
      ],
      isSystem: true,
    ),
  ];
}
