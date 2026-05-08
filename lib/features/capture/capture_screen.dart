import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'recording_controller.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _titleCtrl = TextEditingController();
  final _patientCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _patientCtrl.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }

  Future<bool> _confirmDiscard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate800,
        title: const Text('Discard recording?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete the audio you just captured. This cannot be undone.',
          style: TextStyle(color: AppColors.slate400),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordingControllerProvider);
    final controller = ref.read(recordingControllerProvider.notifier);

    // Navigate to the new note when upload completes.
    ref.listen(recordingControllerProvider, (prev, next) {
      if (next.phase == RecordingPhase.done && next.createdNote != null) {
        context.go('/notes/${next.createdNote!.id}');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Capture visit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (state.isActive || state.recordedFilePath != null) {
              if (await _confirmDiscard()) {
                await controller.cancel();
                if (context.mounted) context.go('/dashboard');
              }
              return;
            }
            if (context.mounted) context.go('/dashboard');
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              if (state.warnApproachingLimit)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Recording will stop automatically at 2:00:00.',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              if (state.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(child: _RecordingFace(state: state, formatDuration: _formatDuration)),
              const SizedBox(height: 16),
              if (state.phase == RecordingPhase.idle && state.recordedFilePath == null)
                _IdleControls(onStart: controller.start)
              else if (state.phase == RecordingPhase.recording)
                _RecordingControls(
                  onPause: controller.pause,
                  onStop: controller.stop,
                )
              else if (state.phase == RecordingPhase.paused)
                _PausedControls(
                  onResume: controller.resume,
                  onStop: controller.stop,
                )
              else if (state.phase == RecordingPhase.idle && state.recordedFilePath != null)
                _SaveControls(
                  titleCtrl: _titleCtrl,
                  patientCtrl: _patientCtrl,
                  onUpload: () {
                    final title = _titleCtrl.text.trim().isEmpty
                        ? 'Visit ${DateTime.now().toIso8601String().substring(0, 16)}'
                        : _titleCtrl.text.trim();
                    controller.uploadAndCreateNote(
                      title: title,
                      patientName: _patientCtrl.text.trim().isEmpty ? null : _patientCtrl.text.trim(),
                    );
                  },
                  onDiscard: () async {
                    if (await _confirmDiscard()) {
                      await controller.cancel();
                      _titleCtrl.clear();
                      _patientCtrl.clear();
                    }
                  },
                )
              else if (state.phase == RecordingPhase.uploading || state.phase == RecordingPhase.finalising)
                _UploadingIndicator(progress: state.uploadProgress, phase: state.phase)
              else if (state.phase == RecordingPhase.error)
                _ErrorRetry(onRetry: controller.reset),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordingFace extends StatelessWidget {
  final RecordingState state;
  final String Function(Duration) formatDuration;

  const _RecordingFace({required this.state, required this.formatDuration});

  @override
  Widget build(BuildContext context) {
    final isLive = state.phase == RecordingPhase.recording;
    final isPaused = state.phase == RecordingPhase.paused;
    final hasRecording = state.recordedFilePath != null && state.phase == RecordingPhase.idle;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: isLive ? 1.0 : 0.92,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: kEmeraldGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald500.withValues(alpha: isLive ? 0.5 : 0.25),
                    blurRadius: isLive ? 50 : 30,
                    spreadRadius: isLive ? 4 : 0,
                  ),
                ],
              ),
              child: Icon(
                isPaused
                    ? Icons.pause_circle_outline
                    : hasRecording
                        ? Icons.check_circle_outline
                        : Icons.mic,
                color: Colors.white,
                size: 86,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            formatDuration(state.elapsed),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLive
                ? 'Recording…'
                : isPaused
                    ? 'Paused'
                    : hasRecording
                        ? 'Recording saved — review and upload'
                        : 'Tap the button below to start',
            style: TextStyle(
              color: isLive ? AppColors.emerald400 : AppColors.slate400,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleControls extends StatelessWidget {
  final VoidCallback onStart;
  const _IdleControls({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: kEmeraldGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald500.withValues(alpha: 0.4),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onStart,
            borderRadius: BorderRadius.circular(20),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fiber_manual_record, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Start recording',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordingControls extends StatelessWidget {
  final VoidCallback onPause;
  final VoidCallback onStop;
  const _RecordingControls({required this.onPause, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PillButton(
            icon: Icons.pause,
            label: 'Pause',
            color: AppColors.warning,
            onTap: onPause,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PillButton(
            icon: Icons.stop,
            label: 'Stop',
            color: AppColors.danger,
            onTap: onStop,
            filled: true,
          ),
        ),
      ],
    );
  }
}

class _PausedControls extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onStop;
  const _PausedControls({required this.onResume, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PillButton(
            icon: Icons.play_arrow,
            label: 'Resume',
            color: AppColors.emerald500,
            onTap: onResume,
            filled: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PillButton(
            icon: Icons.stop,
            label: 'Stop',
            color: AppColors.danger,
            onTap: onStop,
          ),
        ),
      ],
    );
  }
}

class _SaveControls extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController patientCtrl;
  final VoidCallback onUpload;
  final VoidCallback onDiscard;

  const _SaveControls({
    required this.titleCtrl,
    required this.patientCtrl,
    required this.onUpload,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: titleCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Note title (optional)',
            prefixIcon: Icon(Icons.title, color: AppColors.slate400),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: patientCtrl,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Patient name (optional)',
            prefixIcon: Icon(Icons.person_outline, color: AppColors.slate400),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _PillButton(
                icon: Icons.delete_outline,
                label: 'Discard',
                color: AppColors.danger,
                onTap: onDiscard,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _PillButton(
                icon: Icons.cloud_upload_outlined,
                label: 'Upload & generate note',
                color: AppColors.emerald500,
                filled: true,
                onTap: onUpload,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UploadingIndicator extends StatelessWidget {
  final double progress;
  final RecordingPhase phase;

  const _UploadingIndicator({required this.progress, required this.phase});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).clamp(0, 100).toInt();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: phase == RecordingPhase.uploading ? progress : null,
            minHeight: 8,
            backgroundColor: AppColors.cardBg,
            valueColor: const AlwaysStoppedAnimation(AppColors.emerald400),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          phase == RecordingPhase.uploading
              ? 'Uploading audio… $pct%'
              : 'Finalising recording…',
          style: const TextStyle(color: AppColors.slate400, fontSize: 13),
        ),
      ],
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _PillButton(
      icon: Icons.refresh,
      label: 'Try again',
      color: AppColors.emerald500,
      filled: true,
      onTap: onRetry,
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Material(
        color: filled ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: filled ? null : Border.all(color: color, width: 1.5),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: filled ? Colors.white : color, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: filled ? Colors.white : color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
