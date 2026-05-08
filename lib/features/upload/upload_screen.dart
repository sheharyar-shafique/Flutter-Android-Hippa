import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/audio_api.dart';
import '../../core/theme/app_theme.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _titleCtrl = TextEditingController();
  final _patientCtrl = TextEditingController();
  PlatformFile? _file;
  bool _uploading = false;
  double _progress = 0;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _patientCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'flac', 'mp4'],
      withData: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _file = result.files.single;
        _error = null;
        if (_titleCtrl.text.trim().isEmpty) {
          _titleCtrl.text = _file!.name.split('.').first;
        }
      });
    }
  }

  Future<void> _upload() async {
    final f = _file;
    if (f == null || f.path == null) {
      setState(() => _error = 'Please pick an audio file first.');
      return;
    }

    setState(() {
      _uploading = true;
      _progress = 0;
      _error = null;
    });

    try {
      final note = await ref.read(audioApiProvider).upload(
            filePath: f.path!,
            filename: f.name,
            title: _titleCtrl.text.trim().isEmpty ? f.name : _titleCtrl.text.trim(),
            patientName: _patientCtrl.text.trim().isEmpty ? null : _patientCtrl.text.trim(),
            onProgress: (sent, total) {
              if (total > 0) {
                setState(() => _progress = sent / total);
              }
            },
          );
      setState(() {
        _uploading = false;
        _progress = 1;
      });
      if (!mounted) return;
      context.go('/notes/${note.id}');
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _uploading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Upload failed: $e';
        _uploading = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Upload audio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 13))),
                    ],
                  ),
                ),
              _DropZone(file: _file, onTap: _uploading ? null : _pickFile, formatBytes: _formatBytes),
              const SizedBox(height: 18),
              TextField(
                controller: _titleCtrl,
                enabled: !_uploading,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Note title (optional)',
                  prefixIcon: Icon(Icons.title, color: AppColors.slate400),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _patientCtrl,
                enabled: !_uploading,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Patient name (optional)',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.slate400),
                ),
              ),
              const Spacer(),
              if (_uploading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    backgroundColor: AppColors.cardBg,
                    valueColor: const AlwaysStoppedAnimation(AppColors.emerald400),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Uploading… ${(_progress * 100).clamp(0, 100).toInt()}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.slate400),
                ),
                const SizedBox(height: 16),
              ] else
                SizedBox(
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: kEmeraldGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emerald500.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _file == null ? null : _upload,
                        borderRadius: BorderRadius.circular(16),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Upload & generate note',
                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  final PlatformFile? file;
  final VoidCallback? onTap;
  final String Function(int) formatBytes;

  const _DropZone({required this.file, required this.onTap, required this.formatBytes});

  @override
  Widget build(BuildContext context) {
    final picked = file != null;
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: picked
                  ? AppColors.emerald400.withValues(alpha: 0.5)
                  : AppColors.cardBorder,
              width: 1.5,
              style: picked ? BorderStyle.solid : BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  picked ? Icons.audio_file : Icons.upload_file,
                  size: 30,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                picked ? file!.name : 'Tap to select an audio file',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                picked
                    ? formatBytes(file!.size)
                    : 'Supports MP3, M4A, WAV, AAC, OGG, FLAC, MP4',
                style: const TextStyle(color: AppColors.slate400, fontSize: 12),
              ),
              if (picked) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Change file'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

