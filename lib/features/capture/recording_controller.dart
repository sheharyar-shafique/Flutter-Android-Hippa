import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/api/api_client.dart';
import '../../core/api/audio_api.dart';
import '../../core/api/notes_api.dart';
import '../../core/models/note.dart';
import '../../core/models/template.dart';

/// Mirrors the web's MIN/MAX/WARNING constants in CapturePage.tsx (lines 26-34)
/// — DO NOT diverge. UI logic depends on these matching across platforms.
const Duration kRecordingMinDuration = Duration(seconds: 20);
const Duration kRecordingMaxDuration = Duration(hours: 2);
const Duration kRecordingWarnAt = Duration(hours: 1, minutes: 55);

enum RecordingPhase { idle, recording, paused, finalising, uploading, done, error }

class RecordingState {
  final RecordingPhase phase;
  final Duration elapsed;
  final String? recordedFilePath;
  final double uploadProgress;
  final ClinicalNote? createdNote;
  final String? error;
  final bool warnApproachingLimit;

  /// Patient name attached to this session (web's `patientName`). Required
  /// before the user can start recording — the web throws a toast if empty
  /// (CapturePage.tsx:208).
  final String patientName;

  /// Optional pronoun ("She/Her" / "He/Him" / "They/Them"). Empty when none
  /// selected — matches web behaviour.
  final String patientPronoun;

  /// Template id selected for this session ("soap", "psychiatry", etc.).
  final String selectedTemplateId;

  /// Per-section formatting preferences resolved from the selected template.
  final List<SectionSetting>? sectionSettings;

  /// Status message shown during multi-step processing.
  final String processingMessage;

  const RecordingState({
    this.phase = RecordingPhase.idle,
    this.elapsed = Duration.zero,
    this.recordedFilePath,
    this.uploadProgress = 0,
    this.createdNote,
    this.error,
    this.warnApproachingLimit = false,
    this.patientName = '',
    this.patientPronoun = '',
    this.selectedTemplateId = 'soap',
    this.sectionSettings,
    this.processingMessage = '',
  });

  bool get isActive => phase == RecordingPhase.recording || phase == RecordingPhase.paused;
  bool get meetsMinDuration => elapsed >= kRecordingMinDuration;
  Duration get remainingMin =>
      kRecordingMinDuration - elapsed > Duration.zero
          ? kRecordingMinDuration - elapsed
          : Duration.zero;

  double get minProgress {
    final n = elapsed.inMilliseconds / kRecordingMinDuration.inMilliseconds;
    return n > 1 ? 1 : n;
  }

  RecordingState copyWith({
    RecordingPhase? phase,
    Duration? elapsed,
    String? recordedFilePath,
    double? uploadProgress,
    ClinicalNote? createdNote,
    String? error,
    bool? warnApproachingLimit,
    String? patientName,
    String? patientPronoun,
    String? selectedTemplateId,
    List<SectionSetting>? sectionSettings,
    String? processingMessage,
    bool clearError = false,
    bool clearNote = false,
    bool clearSectionSettings = false,
  }) {
    return RecordingState(
      phase: phase ?? this.phase,
      elapsed: elapsed ?? this.elapsed,
      recordedFilePath: recordedFilePath ?? this.recordedFilePath,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      createdNote: clearNote ? null : (createdNote ?? this.createdNote),
      error: clearError ? null : (error ?? this.error),
      warnApproachingLimit: warnApproachingLimit ?? this.warnApproachingLimit,
      patientName: patientName ?? this.patientName,
      patientPronoun: patientPronoun ?? this.patientPronoun,
      selectedTemplateId: selectedTemplateId ?? this.selectedTemplateId,
      sectionSettings: clearSectionSettings ? null : (sectionSettings ?? this.sectionSettings),
      processingMessage: processingMessage ?? this.processingMessage,
    );
  }
}

final recordingControllerProvider =
    StateNotifierProvider<RecordingController, RecordingState>((ref) {
  final api = ref.watch(audioApiProvider);
  final notes = ref.watch(notesApiProvider);
  return RecordingController(api: api, notes: notes);
});

class RecordingController extends StateNotifier<RecordingState> {
  RecordingController({required AudioApi api, required NotesApi notes})
      : _api = api,
        _notes = notes,
        super(const RecordingState());

  final AudioApi _api;
  final NotesApi _notes;
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _ticker;
  DateTime? _startedAt;
  Duration _accumulated = Duration.zero;
  bool _warned = false;

  void setPatient({String? name, String? pronoun}) {
    state = state.copyWith(
      patientName: name ?? state.patientName,
      patientPronoun: pronoun ?? state.patientPronoun,
    );
  }

  void clearPatient() {
    state = state.copyWith(patientName: '', patientPronoun: '');
  }

  void setTemplate(String id, {List<SectionSetting>? sectionSettings}) {
    state = state.copyWith(
      selectedTemplateId: id,
      sectionSettings: sectionSettings,
      clearSectionSettings: sectionSettings == null,
    );
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String> _newRecordingPath() async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    if (kIsWeb) return 'visit_$stamp.m4a';
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/recordings');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    return '${folder.path}/visit_$stamp.m4a';
  }

  Future<void> start() async {
    if (state.patientName.trim().isEmpty) {
      state = state.copyWith(
        phase: RecordingPhase.error,
        error: 'Patient name is required to start recording.',
      );
      return;
    }

    state = state.copyWith(
      phase: RecordingPhase.idle,
      elapsed: Duration.zero,
      uploadProgress: 0,
      clearError: true,
      clearNote: true,
      warnApproachingLimit: false,
      processingMessage: '',
    );
    _warned = false;
    _accumulated = Duration.zero;

    if (!await _ensureMicPermission()) {
      state = state.copyWith(
        phase: RecordingPhase.error,
        error: 'Microphone permission denied. Enable it in Settings to record visits.',
      );
      return;
    }

    if (!await _recorder.hasPermission()) {
      state = state.copyWith(
        phase: RecordingPhase.error,
        error: 'Cannot access the microphone.',
      );
      return;
    }

    final path = await _newRecordingPath();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    _startedAt = DateTime.now();
    state = state.copyWith(
      phase: RecordingPhase.recording,
      elapsed: Duration.zero,
      recordedFilePath: path,
    );
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final running = _startedAt == null
          ? Duration.zero
          : DateTime.now().difference(_startedAt!);
      final total = _accumulated + running;

      // Hard cap: auto-stop at 2 hours.
      if (total >= kRecordingMaxDuration) {
        stop();
        return;
      }

      state = state.copyWith(
        elapsed: total,
        warnApproachingLimit: total >= kRecordingWarnAt,
      );

      // 5-minute warning, fire once.
      if (!_warned && total >= kRecordingWarnAt) _warned = true;
    });
  }

  Future<void> pause() async {
    if (state.phase != RecordingPhase.recording) return;
    await _recorder.pause();
    if (_startedAt != null) {
      _accumulated += DateTime.now().difference(_startedAt!);
    }
    _startedAt = null;
    _ticker?.cancel();
    state = state.copyWith(phase: RecordingPhase.paused);
  }

  Future<void> resume() async {
    if (state.phase != RecordingPhase.paused) return;
    await _recorder.resume();
    _startedAt = DateTime.now();
    state = state.copyWith(phase: RecordingPhase.recording);
    _startTicker();
  }

  /// Stop & upload. Mirrors handleStopRecording() from the web. Refuses to
  /// stop if the minimum 20-second floor isn't met (returns false; UI uses
  /// this to trigger the shake animation).
  Future<bool> stop() async {
    if (!state.meetsMinDuration && state.isActive) return false;

    _ticker?.cancel();
    if (_startedAt != null) {
      _accumulated += DateTime.now().difference(_startedAt!);
    }
    _startedAt = null;

    state = state.copyWith(phase: RecordingPhase.finalising, elapsed: _accumulated);
    final path = await _recorder.stop();
    if (path == null) {
      state = state.copyWith(
        phase: RecordingPhase.error,
        error: 'Recording could not be saved.',
      );
      return true;
    }

    state = state.copyWith(recordedFilePath: path);
    await _uploadAndCreateNote();
    return true;
  }

  /// Full 4-step pipeline matching the web:
  /// 1. Upload audio file
  /// 2. Transcribe audio
  /// 3. Generate clinical note with AI
  /// 4. Create note in the database
  Future<void> _uploadAndCreateNote() async {
    final path = state.recordedFilePath;
    if (path == null) {
      state = state.copyWith(
        phase: RecordingPhase.error,
        error: 'No recording to upload.',
      );
      return;
    }

    final recordingDuration = state.elapsed.inSeconds;

    try {
      // ── Step 1: Upload audio ──
      state = state.copyWith(
        phase: RecordingPhase.uploading,
        uploadProgress: 0,
        processingMessage: 'Uploading audio…',
      );

      final uploadResult = await _api.upload(
        filePath: path,
        filename: path.split(Platform.pathSeparator).last,
        onProgress: (sent, total) {
          if (total <= 0) return;
          state = state.copyWith(uploadProgress: sent / total);
        },
      );

      // ── Step 2: Transcribe ──
      state = state.copyWith(
        phase: RecordingPhase.finalising,
        processingMessage: 'Transcribing audio…',
        uploadProgress: 1,
      );

      final transcription = await _api.transcribe(uploadResult.id);
      final transcriptText = transcription.transcription.trim();

      if (transcriptText.isEmpty) {
        state = state.copyWith(
          phase: RecordingPhase.error,
          error: 'No speech detected. Please speak clearly during the visit.',
        );
        return;
      }

      // ── Step 3: Generate note content with AI ──
      state = state.copyWith(
        processingMessage: 'Generating clinical note with AI…',
      );

      final noteResult = await _api.generateNote(
        transcription: transcriptText,
        template: state.selectedTemplateId,
        patientName: state.patientName.isEmpty ? null : state.patientName,
        sectionSettings: state.sectionSettings
            ?.map((s) => s.toJson())
            .toList(),
      );

      // ── Step 4: Create note in database ──
      state = state.copyWith(
        processingMessage: 'Saving note…',
      );

      final createdNote = await _notes.create(
        patientName: state.patientName.isEmpty ? 'Unknown Patient' : state.patientName,
        dateOfService: DateTime.now().toIso8601String().split('T')[0],
        template: state.selectedTemplateId,
        content: noteResult.content,
        transcription: transcriptText,
        processingTime: recordingDuration,
      );

      state = state.copyWith(
        phase: RecordingPhase.done,
        createdNote: createdNote,
        uploadProgress: 1,
        processingMessage: 'Note generated successfully!',
      );
    } on ApiException catch (e) {
      state = state.copyWith(phase: RecordingPhase.error, error: e.message);
    } catch (e) {
      state = state.copyWith(phase: RecordingPhase.error, error: 'Processing failed: $e');
    }
  }

  /// Cancel and discard the recording without uploading. Used by the
  /// "Reset" button on the paused state.
  Future<void> reset() async {
    _ticker?.cancel();
    if (await _recorder.isRecording() || await _recorder.isPaused()) {
      await _recorder.stop();
    }
    final path = state.recordedFilePath;
    if (path != null) {
      try {
        final f = File(path);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
    _startedAt = null;
    _accumulated = Duration.zero;
    _warned = false;
    state = const RecordingState().copyWith(
      patientName: state.patientName,
      patientPronoun: state.patientPronoun,
      selectedTemplateId: state.selectedTemplateId,
    );
  }

  /// Provides access to existing notes' patient names for the autocomplete
  /// dropdown. Returns most-recent-first, deduplicated, lower-case-collated.
  Future<List<String>> recentPatientNames({int limit = 50}) async {
    try {
      final page = await _notes.list(limit: limit);
      final seen = <String>{};
      final out = <String>[];
      for (final n in page.notes) {
        final name = n.patientName?.trim() ?? '';
        if (name.isEmpty) continue;
        if (!seen.add(name.toLowerCase())) continue;
        out.add(name);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}

/// FutureProvider for the patient-autocomplete dropdown.
final recentPatientNamesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  return ref.read(recordingControllerProvider.notifier).recentPatientNames();
});
