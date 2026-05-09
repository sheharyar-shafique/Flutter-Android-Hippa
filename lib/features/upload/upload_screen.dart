import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/audio_api.dart';
import '../../core/api/notes_api.dart';
import '../../core/theme/app_theme.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});
  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _patientCtrl = TextEditingController();
  PlatformFile? _file;
  bool _uploading = false;
  double _progress = 0;
  String? _error;
  String _statusMsg = '';
  String _template = 'soap';

  @override
  void dispose() { _patientCtrl.dispose(); super.dispose(); }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'flac', 'mp4', 'webm'], withData: false);
    if (result != null && result.files.isNotEmpty) setState(() { _file = result.files.single; _error = null; });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  Future<void> _upload() async {
    final f = _file;
    if (f == null || f.path == null) { setState(() => _error = 'Please pick an audio file first.'); return; }
    setState(() { _uploading = true; _progress = 0; _error = null; _statusMsg = 'Uploading audio…'; });
    try {
      final audioApi = ref.read(audioApiProvider);
      final notesApi = ref.read(notesApiProvider);
      final uploadResult = await audioApi.upload(filePath: f.path!, filename: f.name, onProgress: (sent, total) { if (total > 0) setState(() => _progress = sent / total); });
      setState(() => _statusMsg = 'Transcribing audio…');
      final transcription = await audioApi.transcribe(uploadResult.id);
      final transcriptText = transcription.transcription.trim();
      if (transcriptText.isEmpty) { setState(() { _error = 'No speech detected in the audio file.'; _uploading = false; }); return; }
      setState(() => _statusMsg = 'Generating clinical note with AI…');
      final noteResult = await audioApi.generateNote(transcription: transcriptText, template: _template, patientName: _patientCtrl.text.trim().isEmpty ? null : _patientCtrl.text.trim());
      setState(() => _statusMsg = 'Saving note…');
      final createdNote = await notesApi.create(patientName: _patientCtrl.text.trim().isEmpty ? 'Unknown Patient' : _patientCtrl.text.trim(), dateOfService: DateTime.now().toIso8601String().split('T')[0], template: _template, content: noteResult.content, transcription: transcriptText);
      setState(() { _uploading = false; _progress = 1; });
      if (!mounted) return;
      context.push('/notes/${createdNote.id}');
    } on ApiException catch (e) {
      setState(() { _error = e.message; _uploading = false; });
    } catch (e) {
      setState(() { _error = 'Processing failed: $e'; _uploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), children: [
        // Header
        Row(children: [
          GestureDetector(onTap: () => context.canPop() ? context.pop() : context.go('/dashboard'),
            child: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x1AFFFFFF))),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18))),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Upload Audio', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            Text("Upload a pre-recorded audio file and we'll transcribe it into clinical notes.", style: TextStyle(color: AppColors.slate400, fontSize: 12)),
          ])),
        ]),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.12), border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [const Icon(Icons.error_outline, color: AppColors.danger, size: 18), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 12)))])),
        ],
        const SizedBox(height: 16),

        // Main card: patient name + drop zone
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x14FFFFFF))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Patient Name (Optional)', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(controller: _patientCtrl, enabled: !_uploading, style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(hintText: 'Enter patient name', hintStyle: const TextStyle(color: AppColors.slate500, fontSize: 13), filled: true, fillColor: const Color(0x0DFFFFFF), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.emerald400.withValues(alpha: 0.5))))),
            const SizedBox(height: 16),
            // Drop zone
            GestureDetector(
              onTap: _uploading ? null : _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _file != null ? AppColors.emerald400.withValues(alpha: 0.5) : AppColors.slate500.withValues(alpha: 0.4), width: 1.5, style: BorderStyle.solid),
                  color: const Color(0x08FFFFFF)),
                child: Column(children: [
                  Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(16)),
                    child: Icon(_file != null ? Icons.audio_file : Icons.cloud_upload_outlined, color: _file != null ? AppColors.emerald400 : AppColors.slate400, size: 26)),
                  const SizedBox(height: 14),
                  Text(_file != null ? _file!.name : 'Drop your audio file here', style: TextStyle(color: _file != null ? AppColors.emerald400 : Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(_file != null ? _formatBytes(_file!.size) : 'or click to browse', style: const TextStyle(color: AppColors.slate400, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(_file != null ? 'Tap to change file' : 'Supports MP3, WAV, M4A, OGG, WebM (Max 500MB)', style: const TextStyle(color: AppColors.slate500, fontSize: 11)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Progress
        if (_uploading) ...[
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x14FFFFFF))),
            child: Column(children: [
              ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: _progress, minHeight: 6, backgroundColor: AppColors.slate700, valueColor: const AlwaysStoppedAnimation(AppColors.emerald400))),
              const SizedBox(height: 8),
              Text(_statusMsg, style: const TextStyle(color: AppColors.slate400, fontSize: 13)),
            ])),
          const SizedBox(height: 16),
        ],

        // Generate button
        GestureDetector(
          onTap: _uploading || _file == null ? null : _upload,
          child: Container(height: 52, decoration: BoxDecoration(
            gradient: _file != null && !_uploading ? kEmeraldGradient : null,
            color: _file == null || _uploading ? AppColors.slate700 : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _file != null && !_uploading ? [BoxShadow(color: AppColors.emerald500.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))] : null),
            child: Center(child: _uploading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : const Text('Generate Clinical Note', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)))),
        ),
        const SizedBox(height: 16),

        // Note Settings card
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x14FFFFFF))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Note Settings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text('Template', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x1AFFFFFF))),
              child: DropdownButton<String>(value: _template, isExpanded: true, underline: const SizedBox(), dropdownColor: AppColors.slate800, icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.slate400), style: const TextStyle(color: Colors.white, fontSize: 14),
                items: const [DropdownMenuItem(value: 'soap', child: Text('SOAP Note')), DropdownMenuItem(value: 'progress', child: Text('Progress Note')), DropdownMenuItem(value: 'h_and_p', child: Text('H&P Note')), DropdownMenuItem(value: 'psychiatric', child: Text('Psychiatric Eval'))],
                onChanged: (v) { if (v != null) setState(() => _template = v); })),
            const SizedBox(height: 18),
            const Text('Supported Formats', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...['MP3', 'WAV', 'M4A', 'OGG', 'WebM'].map((f) => Padding(padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [const Icon(Icons.check_circle, color: AppColors.emerald400, size: 16), const SizedBox(width: 8), Text(f, style: const TextStyle(color: Colors.white, fontSize: 13))]))),
          ])),
        const SizedBox(height: 14),

        // Best Practices card
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)), color: const Color(0xFFF59E0B).withValues(alpha: 0.06)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 18), SizedBox(width: 8), Text('Best Practices', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800))]),
            const SizedBox(height: 10),
            ...['Ensure audio is clear and audible', 'Avoid excessive background noise', 'Longer files may take more time', 'Files are deleted after processing'].map((t) =>
              Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $t', style: const TextStyle(color: AppColors.slate400, fontSize: 12.5, height: 1.4)))),
          ])),
      ])),
    );
  }
}
