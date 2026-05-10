import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/default_templates.dart';
import '../../core/models/template.dart';
import '../../core/theme/app_theme.dart';
import '../templates/templates_controller.dart';
import 'recording_controller.dart';

/// Mirrors frontend/src/pages/CapturePage.tsx 1:1. Mobile concession:
/// the right-hand Settings panel renders BELOW the recording panel
/// instead of beside it.

/// Sections that default to paragraph styling (narrative text).
/// All other sections default to bullet-point styling.
const _kParagraphSections = {
  'Subjective', 'Chief Complaint', 'HPI',
  'History of Present Illness', 'Medical Decision Making',
};

/// Generates default per-section formatting preferences for built-in
/// templates that don't have explicit sectionSettings stored.
List<SectionSetting> _defaultSectionSettings(List<String> sections) {
  return sections
      .map((title) => SectionSetting(
            title: title,
            verbosity: 'detailed',
            styling: _kParagraphSections.contains(title)
                ? 'paragraph'
                : 'bullet',
          ))
      .toList();
}
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _shakeCtrl;
  bool _showShake = false;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '${h.toString().padLeft(2, '0')}:$m:$s' : '$m:$s';
  }

  Future<void> _onStop() async {
    final state = ref.read(recordingControllerProvider);
    if (!state.meetsMinDuration) {
      _triggerShake();
      _toast(
        'Please record for at least 20 seconds. ${state.remainingMin.inSeconds}s remaining.',
        color: AppColors.danger,
      );
      return;
    }
    final ok = await ref.read(recordingControllerProvider.notifier).stop();
    if (!ok) _triggerShake();
  }

  void _triggerShake() {
    setState(() => _showShake = true);
    _shakeCtrl.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _showShake = false);
    });
  }

  void _toast(String msg, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordingControllerProvider);

    // Auto-navigate to the new note when upload completes — same path as
    // the web (CapturePage.tsx:345).
    ref.listen<RecordingState>(recordingControllerProvider, (prev, next) {
      if (next.phase == RecordingPhase.done && next.createdNote != null) {
        context.go('/notes/${next.createdNote!.id}');
      }
      if (next.phase == RecordingPhase.error && next.error != null) {
        _toast(next.error!, color: AppColors.danger);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Capture Conversation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 4, 4, 14),
                child: Text(
                  "Record your patient visit and we'll auto-generate clinical notes.",
                  style: TextStyle(color: AppColors.slate400, fontSize: 13.5),
                ),
              ),

              // Recording panel — slate gradient card
              _RecordingPanel(
                state: state,
                showShake: _showShake,
                shakeAnim: _shakeCtrl,
                formatTime: _formatTime,
                onStart: () => ref.read(recordingControllerProvider.notifier).start(),
                onPause: () => ref.read(recordingControllerProvider.notifier).pause(),
                onResume: () => ref.read(recordingControllerProvider.notifier).resume(),
                onStop: _onStop,
                onReset: () {
                  ref.read(recordingControllerProvider.notifier).reset();
                  _toast('Recording reset', color: AppColors.emerald500);
                },
                onPickPatient: () => _showPatientPicker(context, state),
                onClearPatient: () =>
                    ref.read(recordingControllerProvider.notifier).clearPatient(),
              ),

              const SizedBox(height: 14),

              // Settings panel (Note Settings + Session Info)
              _SettingsPanel(state: state),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPatientPicker(BuildContext context, RecordingState state) async {
    if (state.isActive || state.phase == RecordingPhase.uploading || state.phase == RecordingPhase.finalising) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.slate800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _PatientPickerSheet(
        onPicked: (name) {
          ref.read(recordingControllerProvider.notifier).setPatient(name: name);
        },
        onNewPatient: () async {
          Navigator.pop(ctx);
          await _showNewPatientDialog(context);
        },
      ),
    );
  }

  Future<void> _showNewPatientDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    String pronoun = '-';
    final result = await showDialog<({String name, String pronoun})?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppColors.slate900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Patient',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              SizedBox(height: 4),
              Text("Please add the patient's name and pronoun",
                  style: TextStyle(color: AppColors.slate400, fontSize: 12.5, fontWeight: FontWeight.normal)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: DropdownButtonFormField<String>(
                        value: pronoun,
                        dropdownColor: AppColors.slate800,
                        iconEnabledColor: AppColors.slate400,
                        items: const ['-', 'She/Her', 'He/Him', 'They/Them']
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (v) => setSt(() => pronoun = v ?? '-'),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0x0DFFFFFF),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Patient Name',
                          hintStyle: const TextStyle(color: AppColors.slate500),
                          filled: true,
                          fillColor: const Color(0x0DFFFFFF),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              style: TextButton.styleFrom(foregroundColor: AppColors.slate400),
              child: const Text('Cancel'),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx, (name: nameCtrl.text.trim(), pronoun: pronoun));
                },
                child: const Text('Create', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      ref.read(recordingControllerProvider.notifier).setPatient(
            name: result.name,
            pronoun: result.pronoun == '-' ? '' : result.pronoun,
          );
      _toast('Patient added!', color: AppColors.emerald500);
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Recording panel
// ─────────────────────────────────────────────────────────────────

class _RecordingPanel extends StatelessWidget {
  final RecordingState state;
  final bool showShake;
  final AnimationController shakeAnim;
  final String Function(Duration) formatTime;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onReset;
  final VoidCallback onPickPatient;
  final VoidCallback onClearPatient;

  const _RecordingPanel({
    required this.state,
    required this.showShake,
    required this.shakeAnim,
    required this.formatTime,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onReset,
    required this.onPickPatient,
    required this.onClearPatient,
  });

  bool get _isProcessing =>
      state.phase == RecordingPhase.uploading ||
      state.phase == RecordingPhase.finalising;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.slate900, AppColors.slate800, AppColors.slate900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _PatientField(
            state: state,
            onPick: onPickPatient,
            onClear: onClearPatient,
          ),
          const SizedBox(height: 22),
          _TimerDisplay(state: state, isProcessing: _isProcessing, formatTime: formatTime),
          const SizedBox(height: 22),
          _Controls(
            state: state,
            isProcessing: _isProcessing,
            showShake: showShake,
            shakeAnim: shakeAnim,
            onStart: onStart,
            onPause: onPause,
            onResume: onResume,
            onStop: onStop,
            onReset: onReset,
          ),
          const SizedBox(height: 24),
          const _TipsCard(),
          if (state.phase == RecordingPhase.idle) ...[
            const SizedBox(height: 12),
            _DemoButton(),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Patient name field
// ─────────────────────────────────────────────────────────────────

class _PatientField extends StatelessWidget {
  final RecordingState state;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _PatientField({
    required this.state,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final filled = state.patientName.isNotEmpty;
    final disabled = state.isActive ||
        state.phase == RecordingPhase.uploading ||
        state.phase == RecordingPhase.finalising;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6, left: 2),
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 13, color: AppColors.slate400),
              SizedBox(width: 5),
              Text(
                'Patient Name',
                style: TextStyle(
                  color: AppColors.slate300,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: 4),
              Text('*',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  )),
            ],
          ),
        ),
        Opacity(
          opacity: disabled ? 0.6 : 1,
          child: Material(
            color: filled ? AppColors.emerald500.withValues(alpha: 0.06) : const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: disabled ? null : onPick,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: filled
                        ? AppColors.emerald500.withValues(alpha: 0.4)
                        : const Color(0x1FFFFFFF),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        filled ? state.patientName : 'Click to add patient…',
                        style: TextStyle(
                          color: filled ? Colors.white : AppColors.slate500,
                          fontSize: 13.5,
                          fontWeight: filled ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (state.patientPronoun.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x338B5CF6),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: const Color(0x4D8B5CF6)),
                        ),
                        child: Text(state.patientPronoun,
                            style: const TextStyle(
                              color: Color(0xFFC4B5FD),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (filled && !disabled)
                      InkWell(
                        onTap: onClear,
                        borderRadius: BorderRadius.circular(50),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(Icons.close, size: 16, color: AppColors.slate500),
                        ),
                      )
                    else if (!filled)
                      const Icon(Icons.expand_more, size: 16, color: AppColors.slate500),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Timer display
// ─────────────────────────────────────────────────────────────────

class _TimerDisplay extends StatelessWidget {
  final RecordingState state;
  final bool isProcessing;
  final String Function(Duration) formatTime;

  const _TimerDisplay({
    required this.state,
    required this.isProcessing,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      final msg = state.processingMessage.isNotEmpty
          ? state.processingMessage
          : (state.phase == RecordingPhase.uploading
              ? 'Uploading audio… ${(state.uploadProgress * 100).clamp(0, 100).toStringAsFixed(0)}%'
              : 'Processing your recording…');
      return Column(
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.emerald400),
          ),
          const SizedBox(height: 14),
          Text(
            msg,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'This may take 30–60 seconds',
            style: TextStyle(color: AppColors.slate400, fontSize: 12),
          ),
        ],
      );
    }

    final isActive = state.isActive;
    final amber = !state.meetsMinDuration && isActive;

    return Column(
      children: [
        Text(
          formatTime(state.elapsed),
          style: TextStyle(
            color: amber ? AppColors.warning : Colors.white,
            fontSize: 56,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 6),
        if (isActive && !state.meetsMinDuration) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time, size: 13, color: AppColors.warning),
              const SizedBox(width: 4),
              Text(
                'MINIMUM: ${state.remainingMin.inSeconds}s REMAINING',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 220,
            height: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: LinearProgressIndicator(
                value: state.minProgress,
                minHeight: 5,
                backgroundColor: const Color(0x1AFFFFFF),
                color: AppColors.warning,
              ),
            ),
          ),
        ] else if (isActive && state.meetsMinDuration)
          const Text(
            '✓ Minimum reached — stop when ready',
            style: TextStyle(
              color: AppColors.emerald400,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        const SizedBox(height: 10),
        if (state.phase == RecordingPhase.recording) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'Recording',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ] else if (state.phase == RecordingPhase.paused)
          const Text(
            'Paused',
            style: TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w700),
          )
        else if (state.phase == RecordingPhase.idle)
          const Text(
            'Ready to record',
            style: TextStyle(color: AppColors.slate400, fontSize: 13),
          )
        else if (state.phase == RecordingPhase.error && state.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              state.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger, fontSize: 12, height: 1.4),
            ),
          ),
        if (state.warnApproachingLimit && state.phase == RecordingPhase.recording) ...[
          const SizedBox(height: 8),
          const Text(
            '⏰ Recording will auto-stop in 5 minutes (2-hour max)',
            style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Controls (Mic / Pause / Stop / Resume / Reset)
// ─────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  final RecordingState state;
  final bool isProcessing;
  final bool showShake;
  final AnimationController shakeAnim;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onReset;

  const _Controls({
    required this.state,
    required this.isProcessing,
    required this.showShake,
    required this.shakeAnim,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    if (isProcessing) return const SizedBox.shrink();
    if (state.phase == RecordingPhase.idle || state.phase == RecordingPhase.error) {
      return _BigMicButton(onTap: onStart);
    }
    if (state.phase == RecordingPhase.recording) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CircleButton(
            icon: Icons.pause,
            color: AppColors.warning,
            background: AppColors.warning.withValues(alpha: 0.18),
            border: AppColors.warning,
            size: 60,
            onTap: onPause,
          ),
          const SizedBox(width: 16),
          _ShakeBox(
            running: showShake,
            controller: shakeAnim,
            child: _StopButton(meetsMin: state.meetsMinDuration, onTap: onStop, remaining: state.remainingMin),
          ),
        ],
      );
    }
    if (state.phase == RecordingPhase.paused) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CircleButton(
            icon: Icons.play_arrow,
            color: AppColors.emerald400,
            background: AppColors.emerald500.withValues(alpha: 0.18),
            border: AppColors.emerald400,
            size: 60,
            onTap: onResume,
          ),
          const SizedBox(width: 14),
          _ShakeBox(
            running: showShake,
            controller: shakeAnim,
            child: _StopButton(meetsMin: state.meetsMinDuration, onTap: onStop, remaining: state.remainingMin),
          ),
          const SizedBox(width: 14),
          _CircleButton(
            icon: Icons.refresh,
            color: AppColors.slate400,
            background: const Color(0x1AFFFFFF),
            border: const Color(0x33FFFFFF),
            size: 56,
            onTap: onReset,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _BigMicButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BigMicButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: 1.3),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (_, scale, __) => Transform.scale(
              scale: scale,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald500.withValues(alpha: 0.12),
                ),
              ),
            ),
            onEnd: () {},
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: kEmeraldGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald500.withValues(alpha: 0.5),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: const SizedBox(
                  width: 96,
                  height: 96,
                  child: Center(
                    child: Icon(Icons.mic, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  final bool meetsMin;
  final VoidCallback onTap;
  final Duration remaining;
  const _StopButton({required this.meetsMin, required this.onTap, required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: meetsMin ? AppColors.danger : const Color(0xFF475569),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (meetsMin ? AppColors.danger : Colors.black)
                    .withValues(alpha: 0.4),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Opacity(
            opacity: meetsMin ? 1 : 0.6,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: const SizedBox(
                  width: 96,
                  height: 96,
                  child: Center(
                    child: Icon(Icons.stop, color: Colors.white, size: 36),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!meetsMin)
          Positioned(
            bottom: -22,
            child: Text(
              '${remaining.inSeconds}s left',
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final Color border;
  final double size;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.background,
    required this.border,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: Ink(
          decoration: ShapeDecoration(
            color: background,
            shape: CircleBorder(side: BorderSide(color: border, width: 2)),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(child: Icon(icon, color: color, size: size * 0.4)),
          ),
        ),
      ),
    );
  }
}

class _ShakeBox extends StatelessWidget {
  final bool running;
  final AnimationController controller;
  final Widget child;
  const _ShakeBox({required this.running, required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!running) return child;
    return AnimatedBuilder(
      animation: controller,
      builder: (_, c) {
        final t = controller.value;
        // Sinusoidal shake — amplitude tapers off so the card doesn't rattle
        // forever after the user releases.
        final dx = 8 * (1 - t) *
            (t < 0.25
                ? 1
                : t < 0.5
                    ? -1
                    : t < 0.75
                        ? 1
                        : -1);
        return Transform.translate(offset: Offset(dx, 0), child: c);
      },
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tips card + demo button
// ─────────────────────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Tips for best results',
            style: TextStyle(
              color: AppColors.emerald400,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          _TipLine(text: 'Minimum 20 seconds required per recording', highlight: true),
          _TipLine(text: 'Speak clearly and at a natural pace'),
          _TipLine(text: 'Minimize background noise'),
          _TipLine(text: 'State important details explicitly'),
        ],
      ),
    );
  }
}

class _TipLine extends StatelessWidget {
  final String text;
  final bool highlight;
  const _TipLine({required this.text, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(color: AppColors.slate400, fontSize: 12.5),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: highlight ? AppColors.warning : AppColors.slate400,
                fontSize: 12.5,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x12A78BFA),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          // Demo session route not implemented yet on the app side.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF8B5CF6),
              content: Text('Demo session coming soon.', style: TextStyle(color: Colors.white)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x338B5CF6)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow, size: 14, color: Color(0xFFA78BFA)),
              SizedBox(width: 6),
              Text(
                'New to Pronote? Try a demo session',
                style: TextStyle(
                  color: Color(0xFFA78BFA),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Settings panel
// ─────────────────────────────────────────────────────────────────

class _SettingsPanel extends ConsumerWidget {
  final RecordingState state;
  const _SettingsPanel({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesState = ref.watch(templatesControllerProvider);
    final myTemplates = templatesState.myTemplates.isEmpty
        ? templatesState.allTemplates
        : templatesState.myTemplates;

    final selected = myTemplates.firstWhere(
      (t) => t.id == state.selectedTemplateId,
      orElse: () => myTemplates.isNotEmpty ? myTemplates.first : kDefaultTemplates.first,
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x0AFFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Note Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _TemplateDropdown(
                templates: myTemplates,
                selectedId: state.selectedTemplateId,
                onChanged: (id) {
                  if (id != null) {
                    final tpl = myTemplates.firstWhere(
                      (t) => t.id == id,
                      orElse: () => myTemplates.first,
                    );
                    // Use saved sectionSettings if available, otherwise
                    // auto-generate defaults (paragraph for narrative
                    // sections, bullet for the rest — matches web).
                    final settings = tpl.sectionSettings ??
                        _defaultSectionSettings(tpl.sections);
                    ref.read(recordingControllerProvider.notifier).setTemplate(
                      id,
                      sectionSettings: settings,
                    );
                  }
                },
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0x14FFFFFF), height: 1),
              const SizedBox(height: 12),
              const Text(
                'Template Sections',
                style: TextStyle(
                  color: AppColors.slate300,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              if (selected.sections.isEmpty)
                const Text(
                  'No sections defined yet',
                  style: TextStyle(
                    color: AppColors.slate500,
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                ...selected.sections.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.emerald500,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s,
                            style: const TextStyle(color: AppColors.slate400, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x0AFFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Session Info',
                style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Status',
                value: _statusLabel(state.phase),
                badgeBg: _statusBg(state.phase),
                badgeBorder: _statusBorder(state.phase),
                badgeFg: _statusFg(state.phase),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Duration',
                value: _durationStr(state.elapsed),
                isMono: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _statusLabel(RecordingPhase p) => switch (p) {
        RecordingPhase.idle => 'Idle',
        RecordingPhase.recording => 'Recording',
        RecordingPhase.paused => 'Paused',
        RecordingPhase.finalising => 'Finalising',
        RecordingPhase.uploading => 'Uploading',
        RecordingPhase.done => 'Completed',
        RecordingPhase.error => 'Error',
      };

  Color _statusFg(RecordingPhase p) {
    switch (p) {
      case RecordingPhase.recording:
        return AppColors.danger;
      case RecordingPhase.paused:
      case RecordingPhase.finalising:
      case RecordingPhase.uploading:
        return AppColors.warning;
      case RecordingPhase.done:
        return AppColors.emerald400;
      case RecordingPhase.error:
        return AppColors.danger;
      default:
        return AppColors.slate400;
    }
  }

  Color _statusBg(RecordingPhase p) => _statusFg(p).withValues(alpha: 0.18);
  Color _statusBorder(RecordingPhase p) => _statusFg(p).withValues(alpha: 0.4);

  String _durationStr(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '${h.toString().padLeft(2, '0')}:$m:$s' : '$m:$s';
  }
}

class _TemplateDropdown extends StatelessWidget {
  final List<NoteTemplate> templates;
  final String selectedId;
  final ValueChanged<String?> onChanged;

  const _TemplateDropdown({
    required this.templates,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelected = templates.any((t) => t.id == selectedId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6, left: 2),
          child: Text(
            'Template',
            style: TextStyle(
              color: AppColors.slate400,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: hasSelected ? selectedId : (templates.isNotEmpty ? templates.first.id : null),
              dropdownColor: AppColors.slate800,
              iconEnabledColor: AppColors.slate400,
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              items: templates
                  .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? badgeBg;
  final Color? badgeBorder;
  final Color? badgeFg;
  final bool isMono;

  const _InfoRow({
    required this.label,
    required this.value,
    this.badgeBg,
    this.badgeBorder,
    this.badgeFg,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    final isBadge = badgeBg != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.slate400, fontSize: 12.5)),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: badgeBorder!),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: badgeFg,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFeatures: isMono ? const [FontFeature.tabularFigures()] : null,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Patient picker bottom sheet
// ─────────────────────────────────────────────────────────────────

class _PatientPickerSheet extends ConsumerStatefulWidget {
  final ValueChanged<String> onPicked;
  final VoidCallback onNewPatient;

  const _PatientPickerSheet({required this.onPicked, required this.onNewPatient});

  @override
  ConsumerState<_PatientPickerSheet> createState() => _PatientPickerSheetState();
}

class _PatientPickerSheetState extends ConsumerState<_PatientPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final names = ref.watch(recentPatientNamesProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.slate500,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Patient Name',
                hintStyle: const TextStyle(color: AppColors.slate500),
                prefixIcon: const Icon(Icons.search, color: AppColors.slate500, size: 18),
                filled: true,
                fillColor: const Color(0x0DFFFFFF),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.info.withValues(alpha: 0.5), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            names.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator(color: AppColors.emerald400)),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (list) {
                final filtered = _query.isEmpty
                    ? list
                    : list.where((n) => n.toLowerCase().contains(_query.toLowerCase())).toList();
                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        _query.isEmpty
                            ? 'No saved patients yet'
                            : 'No matching patients',
                        style: const TextStyle(color: AppColors.slate500, fontSize: 12.5),
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, top: 4, bottom: 4),
                      child: Text(
                        'RECENT PATIENTS',
                        style: TextStyle(
                          color: AppColors.slate500,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (_, i) {
                          final n = filtered[i];
                          return Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                widget.onPicked(n);
                                Navigator.pop(context);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: AppColors.info.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          n.substring(0, 1).toUpperCase(),
                                          style: TextStyle(
                                            color: AppColors.info,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(n, style: const TextStyle(color: Colors.white, fontSize: 13.5)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const Divider(color: Color(0x14FFFFFF), height: 14),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // If user typed a name and there's no exact match, use it
                  // directly (matches web behaviour at line 495-501).
                  if (_query.trim().isNotEmpty) {
                    widget.onPicked(_query.trim());
                    Navigator.pop(context);
                  } else {
                    widget.onNewPatient();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: Color(0xFFA78BFA), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _query.trim().isNotEmpty ? 'Use "${_query.trim()}"' : 'New Patient',
                        style: const TextStyle(
                          color: Color(0xFFA78BFA),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
