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

/// Hard cap on recording length — matches the web app's 2-hour business rule.
/// Five-minute warning shown when the user crosses the 1h55m mark.
const Duration kRecordingMaxDuration = Duration(hours: 2);
const Duration kRecordingWarnAt = Duration(hours: 1, minutes: 55);

enum RecordingPhase { idle, recording, paused, finalising, uploading, done, error }

class RecordingState {
  final RecordingPhase phase;
  final Duration elapsed;
  final String? recordedFilePath;
  final double uploadProgress; // 0.0 .. 1.0
  final ClinicalNote? createdNote;
  final String? error;
  final bool warnApproachingLimit;

  const RecordingState({
    this.phase = RecordingPhase.idle,
    this.elapsed = Duration.zero,
    this.recordedFilePath,
    this.uploadProgress = 0,
    this.createdNote,
    this.error,
    this.warnApproachingLimit = false,
  });

  bool get isActive => phase == RecordingPhase.recording || phase == RecordingPhase.paused;

  RecordingState copyWith({
    RecordingPhase? phase,
    Duration? elapsed,
    String? recordedFilePath,
    double? uploadProgress,
    ClinicalNote? createdNote,
    String? error,
    bool? warnApproachingLimit,
    bool clearError = false,
    bool clearNote = false,
  }) {
    return RecordingState(
      phase: phase ?? this.phase,
      elapsed: elapsed ?? this.elapsed,
      recordedFilePath: recordedFilePath ?? this.recordedFilePath,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      createdNote: clearNote ? null : (createdNote ?? this.createdNote),
      error: clearError ? null : (error ?? this.error),
      warnApproachingLimit: warnApproachingLimit ?? this.warnApproachingLimit,
    );
  }
}

final recordingControllerProvider =
    StateNotifierProvider.autoDispose<RecordingController, RecordingState>((ref) {
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
  // ignore: unused_field
  final NotesApi _notes;
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _ticker;
  DateTime? _startedAt;
  Duration _accumulated = Duration.zero;

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String> _newRecordingPath() async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    // path_provider has no implementation on Flutter web. The `record`
    // package's web implementation accepts an empty/relative path and
    // streams the recording to a Blob URL itself, so we just return a
    // sentinel filename and let the recorder handle it.
    if (kIsWeb) return 'visit_$stamp.m4a';
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/recordings');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    return '${folder.path}/visit_$stamp.m4a';
  }

  Future<void> start() async {
    state = const RecordingState();
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
    _accumulated = Duration.zero;
    state = state.copyWith(
      phase: RecordingPhase.recording,
      elapsed: Duration.zero,
      recordedFilePath: path,
      clearError: true,
      clearNote: true,
      warnApproachingLimit: false,
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

      if (total >= kRecordingMaxDuration) {
        // Hard stop at 2 hours.
        stop();
        return;
      }

      state = state.copyWith(
        elapsed: total,
        warnApproachingLimit: total >= kRecordingWarnAt,
      );
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

  Future<void> stop() async {
    _ticker?.cancel();
    state = state.copyWith(phase: RecordingPhase.finalising);

    final path = await _recorder.stop();
    if (path == null) {
      state = state.copyWith(
        phase: RecordingPhase.error,
        error: 'Recording could not be saved.',
      );
      return;
    }
    if (_startedAt != null) {
      _accumulated += DateTime.now().difference(_startedAt!);
    }
    _startedAt = null;
    state = state.copyWith(
      phase: RecordingPhase.idle,
      elapsed: _accumulated,
      recordedFilePath: path,
    );
  }

  Future<void> cancel() async {
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
    state = const RecordingState();
  }

  Future<void> uploadAndCreateNote({
    required String title,
    String? patientName,
    String? templateId,
  }) async {
    final path = state.recordedFilePath;
    if (path == null || !File(path).existsSync()) {
      state = state.copyWith(
        phase: RecordingPhase.error,
        error: 'No recording to upload.',
      );
      return;
    }

    state = state.copyWith(phase: RecordingPhase.uploading, uploadProgress: 0);
    try {
      final note = await _api.upload(
        filePath: path,
        filename: path.split(Platform.pathSeparator).last,
        title: title,
        patientName: patientName,
        templateId: templateId,
        onProgress: (sent, total) {
          if (total <= 0) return;
          state = state.copyWith(uploadProgress: sent / total);
        },
      );
      state = state.copyWith(
        phase: RecordingPhase.done,
        createdNote: note,
        uploadProgress: 1,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        phase: RecordingPhase.error,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        phase: RecordingPhase.error,
        error: 'Upload failed: $e',
      );
    }
  }

  void reset() {
    _ticker?.cancel();
    _startedAt = null;
    _accumulated = Duration.zero;
    state = const RecordingState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
