import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/api/api_client.dart';
import '../../core/api/notes_api.dart';
import '../../core/theme/app_theme.dart';

class DictationScreen extends ConsumerStatefulWidget {
  const DictationScreen({super.key});

  @override
  ConsumerState<DictationScreen> createState() => _DictationScreenState();
}

class _DictationScreenState extends ConsumerState<DictationScreen> {
  final SpeechToText _stt = SpeechToText();
  bool _initialised = false;
  bool _available = false;
  bool _listening = false;
  String _transcript = '';
  String _interim = '';
  double _level = 0;
  String? _error;
  bool _saving = false;

  final _titleCtrl = TextEditingController();
  final _patientCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSTT();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _patientCtrl.dispose();
    if (_listening) _stt.stop();
    super.dispose();
  }

  Future<void> _initSTT() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      setState(() => _error = 'Microphone permission denied. Enable it in Settings to dictate.');
      return;
    }

    final ok = await _stt.initialize(
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _error = e.errorMsg;
          _listening = false;
        });
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == SpeechToText.notListeningStatus || status == SpeechToText.doneStatus) {
          setState(() => _listening = false);
        }
      },
    );

    setState(() {
      _initialised = true;
      _available = ok;
      if (!ok && _error == null) {
        _error = 'Speech recognition is not available on this device.';
      }
    });
  }

  Future<void> _toggle() async {
    if (!_available) return;

    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }

    setState(() {
      _error = null;
      _listening = true;
      _interim = '';
    });

    await _stt.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          if (result.finalResult) {
            _transcript += (_transcript.isEmpty ? '' : ' ') + result.recognizedWords;
            _interim = '';
          } else {
            _interim = result.recognizedWords;
          }
        });
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() => _level = level);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      ),
      pauseFor: const Duration(seconds: 8),
      listenFor: const Duration(minutes: 30),
    );
  }

  void _clear() {
    if (_listening) _stt.stop();
    setState(() {
      _transcript = '';
      _interim = '';
      _listening = false;
    });
  }

  Future<void> _save() async {
    if (_transcript.trim().isEmpty) return;
    if (_listening) await _stt.stop();

    setState(() => _saving = true);

    try {
      final note = await ref.read(notesApiProvider).create(
            title: _titleCtrl.text.trim().isEmpty
                ? 'Dictation ${DateTime.now().toIso8601String().substring(0, 16)}'
                : _titleCtrl.text.trim(),
            patientName: _patientCtrl.text.trim().isEmpty ? null : _patientCtrl.text.trim(),
            content: _transcript,
            transcript: _transcript,
          );
      if (!mounted) return;
      context.go('/notes/${note.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Dictation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          if (_transcript.isNotEmpty || _interim.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.delete_outline),
              onPressed: _clear,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
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
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: SingleChildScrollView(
                    reverse: true,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                        children: [
                          if (_transcript.isEmpty && _interim.isEmpty)
                            const TextSpan(
                              text: 'Tap the microphone below and start speaking.\n\nYour words appear here in real-time. The app supports up to 30 minutes of continuous dictation per session.',
                              style: TextStyle(color: AppColors.slate400, fontSize: 14),
                            )
                          else ...[
                            TextSpan(text: _transcript),
                            if (_interim.isNotEmpty)
                              TextSpan(
                                text: ' ${_interim}',
                                style: const TextStyle(color: AppColors.slate400, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (_transcript.isNotEmpty) ...[
                TextField(
                  controller: _titleCtrl,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Note title (optional)',
                    prefixIcon: Icon(Icons.title, color: AppColors.slate400),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _patientCtrl,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Patient name (optional)',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.slate400),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  if (_transcript.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.emerald400))
                            : const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Save as note'),
                      ),
                    ),
                  if (_transcript.isNotEmpty) const SizedBox(width: 12),
                  Expanded(
                    flex: _transcript.isNotEmpty ? 1 : 2,
                    child: SizedBox(
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _listening
                              ? const LinearGradient(colors: [AppColors.danger, Color(0xFFDC2626)])
                              : kEmeraldGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (_listening ? AppColors.danger : AppColors.emerald500)
                                  .withValues(alpha: 0.4 + (_level / 30).clamp(0, 0.5)),
                              blurRadius: 18 + (_level * 2).clamp(0, 20),
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: !_initialised || !_available || _saving ? null : _toggle,
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: !_initialised
                                  ? const SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(_listening ? Icons.stop : Icons.mic, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text(
                                          _listening ? 'Stop' : 'Start dictating',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
