import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/api/api_client.dart';
import '../../core/api/audio_api.dart';
import '../../core/api/notes_api.dart';
import '../../core/theme/app_theme.dart';

class DictationScreen extends ConsumerStatefulWidget {
  const DictationScreen({super.key});
  @override
  ConsumerState<DictationScreen> createState() => _DictationScreenState();
}

class _DictationScreenState extends ConsumerState<DictationScreen> {
  final SpeechToText _stt = SpeechToText();
  final _transcriptCtrl = TextEditingController();
  final _patientCtrl = TextEditingController();
  bool _initialised = false;
  bool _available = false;
  bool _listening = false;
  String _interim = '';
  double _level = 0;
  String? _error;
  bool _generating = false;
  String _template = 'soap';

  @override
  void initState() { super.initState(); _initSTT(); }

  @override
  void dispose() {
    _transcriptCtrl.dispose();
    _patientCtrl.dispose();
    if (_listening) _stt.stop();
    super.dispose();
  }

  Future<void> _initSTT() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) { setState(() => _error = 'Microphone permission denied.'); return; }
    final ok = await _stt.initialize(
      onError: (e) { if (mounted) setState(() { _error = e.errorMsg; _listening = false; }); },
      onStatus: (s) { if (mounted && (s == SpeechToText.notListeningStatus || s == SpeechToText.doneStatus)) setState(() => _listening = false); },
    );
    setState(() { _initialised = true; _available = ok; if (!ok && _error == null) _error = 'Speech recognition not available.'; });
  }

  Future<void> _toggle() async {
    if (!_available) return;
    if (_listening) { await _stt.stop(); setState(() => _listening = false); return; }
    setState(() { _error = null; _listening = true; _interim = ''; });
    await _stt.listen(
      onResult: (r) { if (!mounted) return; setState(() {
        if (r.finalResult) {
          final cur = _transcriptCtrl.text;
          _transcriptCtrl.text = cur + (cur.isEmpty ? '' : ' ') + r.recognizedWords;
          _transcriptCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _transcriptCtrl.text.length));
          _interim = '';
        } else { _interim = r.recognizedWords; }
      }); },
      onSoundLevelChange: (l) { if (mounted) setState(() => _level = l); },
      listenOptions: SpeechListenOptions(partialResults: true, cancelOnError: false, listenMode: ListenMode.dictation),
      pauseFor: const Duration(seconds: 8),
      listenFor: const Duration(minutes: 30),
    );
  }

  void _clear() { if (_listening) _stt.stop(); setState(() { _transcriptCtrl.clear(); _interim = ''; _listening = false; }); }

  Future<void> _generate() async {
    final text = _transcriptCtrl.text.trim();
    if (text.isEmpty) return;
    if (_listening) await _stt.stop();
    setState(() { _generating = true; _error = null; });
    try {
      final audioApi = ref.read(audioApiProvider);
      final notesApi = ref.read(notesApiProvider);
      final noteResult = await audioApi.generateNote(transcription: text, template: _template, patientName: _patientCtrl.text.trim().isEmpty ? null : _patientCtrl.text.trim());
      final created = await notesApi.create(patientName: _patientCtrl.text.trim().isEmpty ? 'Unknown Patient' : _patientCtrl.text.trim(), dateOfService: DateTime.now().toIso8601String().split('T')[0], template: _template, content: noteResult.content, transcription: text);
      if (!mounted) return;
      context.push('/notes/${created.id}');
    } on ApiException catch (e) {
      if (mounted) setState(() { _generating = false; _error = e.message; });
    } catch (e) {
      if (mounted) setState(() { _generating = false; _error = '$e'; });
    }
  }

  int get _wordCount { final t = _transcriptCtrl.text.trim(); return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length; }
  int get _charCount => _transcriptCtrl.text.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), children: [
        // ── Header ──
        Row(children: [
          GestureDetector(onTap: () => context.canPop() ? context.pop() : context.go('/dashboard'),
            child: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x1AFFFFFF))),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18))),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Voice Dictation', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            Text('Dictate your clinical notes directly. Speak naturally and we\'ll transcribe in real-time.', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
          ])),
        ]),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.12), border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [const Icon(Icons.error_outline, color: AppColors.danger, size: 18), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 12)))])),
        ],
        const SizedBox(height: 16),

        // ── Mic button card ──
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x14FFFFFF))),
          child: Column(children: [
            GestureDetector(
              onTap: !_initialised || !_available || _generating ? null : _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _listening ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]) : kEmeraldGradient,
                  boxShadow: [BoxShadow(color: (_listening ? AppColors.danger : AppColors.emerald500).withValues(alpha: 0.4 + (_level / 30).clamp(0.0, 0.4)), blurRadius: 20 + (_level * 2).clamp(0.0, 20.0), offset: const Offset(0, 4))],
                ),
                child: Icon(_listening ? Icons.stop : Icons.mic, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(height: 12),
            Text(_listening ? 'Listening... Tap to stop' : 'Click to start dictation',
                style: const TextStyle(color: AppColors.slate400, fontSize: 13)),
            if (_interim.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8, left: 20, right: 20),
              child: Text(_interim, style: const TextStyle(color: AppColors.slate500, fontStyle: FontStyle.italic, fontSize: 13), textAlign: TextAlign.center)),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Settings ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x14FFFFFF))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            const Text('Patient Name', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(controller: _patientCtrl, style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(hintText: 'Enter patient name', hintStyle: const TextStyle(color: AppColors.slate500, fontSize: 13), filled: true, fillColor: const Color(0x0DFFFFFF), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.emerald400.withValues(alpha: 0.5))))),
            const SizedBox(height: 14),
            const Text('Note Template', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x1AFFFFFF))),
              child: DropdownButton<String>(value: _template, isExpanded: true, underline: const SizedBox(), dropdownColor: AppColors.slate800, icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.slate400),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: const [
                  DropdownMenuItem(value: 'soap', child: Text('SOAP Note')),
                  DropdownMenuItem(value: 'progress', child: Text('Progress Note')),
                  DropdownMenuItem(value: 'h_and_p', child: Text('H&P Note')),
                  DropdownMenuItem(value: 'psychiatric', child: Text('Psychiatric Eval')),
                  DropdownMenuItem(value: 'intake', child: Text('Intake Note')),
                ],
                onChanged: (v) { if (v != null) setState(() => _template = v); }),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Transcript ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x14FFFFFF))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Transcript', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              _IconBtn(icon: Icons.volume_up, onTap: () {}),
              const SizedBox(width: 6),
              _IconBtn(icon: Icons.copy, onTap: () { Clipboard.setData(ClipboardData(text: _transcriptCtrl.text)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))); }),
              const SizedBox(width: 6),
              _IconBtn(icon: Icons.refresh, onTap: _clear),
            ]),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(minHeight: 140),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x14FFFFFF))),
              child: TextField(controller: _transcriptCtrl, maxLines: null, minLines: 5,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                decoration: const InputDecoration.collapsed(hintText: 'Your dictation will appear here... Start speaking or type directly.', hintStyle: TextStyle(color: AppColors.slate500, fontSize: 13)),
                onChanged: (_) => setState(() {})),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$_wordCount words', style: const TextStyle(color: AppColors.emerald400, fontSize: 12)),
              Text('$_charCount characters', style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Generate button ──
        GestureDetector(
          onTap: _generating || _transcriptCtrl.text.trim().isEmpty ? null : _generate,
          child: Container(
            height: 52,
            decoration: BoxDecoration(gradient: _transcriptCtrl.text.trim().isEmpty ? null : kEmeraldGradient,
              color: _transcriptCtrl.text.trim().isEmpty ? AppColors.slate700 : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _transcriptCtrl.text.trim().isNotEmpty ? [BoxShadow(color: AppColors.emerald500.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))] : null),
            child: Center(child: _generating
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.auto_awesome, color: Colors.white, size: 18), SizedBox(width: 8), Text('Generate Clinical Note', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))])),
          ),
        ),
        const SizedBox(height: 16),

        // ── Dictation Tips ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)), color: const Color(0xFFF59E0B).withValues(alpha: 0.06)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Text('💡', style: TextStyle(fontSize: 16)), SizedBox(width: 6), Text('Dictation Tips', style: TextStyle(color: AppColors.emerald400, fontSize: 15, fontWeight: FontWeight.w800))]),
            const SizedBox(height: 10),
            ...[
              'Speak clearly and at a moderate pace',
              'Say "period" or "comma" for punctuation',
              'Use "new line" or "new paragraph" for formatting',
              'Review and edit the transcript before generating',
              'Medical terms are automatically recognized',
            ].map((t) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $t', style: const TextStyle(color: AppColors.emerald400, fontSize: 12.5, height: 1.4)))),
          ]),
        ),
        const SizedBox(height: 14),

        // ── Voice Commands ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x14FFFFFF))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Voice Commands', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _CmdRow(cmd: '"Delete last"', desc: 'Remove word'),
            _CmdRow(cmd: '"Clear all"', desc: 'Reset transcript'),
            _CmdRow(cmd: '"New section"', desc: 'Start new section'),
          ]),
        ),
      ])),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    width: 32, height: 32, decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(8)),
    child: Icon(icon, color: AppColors.slate400, size: 16)));
}

class _CmdRow extends StatelessWidget {
  final String cmd, desc;
  const _CmdRow({required this.cmd, required this.desc});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(cmd, style: const TextStyle(color: AppColors.emerald400, fontSize: 13, fontWeight: FontWeight.w600)),
      Text(desc, style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
    ]));
}
