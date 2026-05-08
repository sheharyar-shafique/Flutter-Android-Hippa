import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Phase 3 stub. Full live speech-to-text streaming arrives in Phase 4 — wired
/// up to a STT package (e.g. speech_to_text) plus the same /audio backend that
/// powers the Capture screen.
class DictationScreen extends StatelessWidget {
  const DictationScreen({super.key});

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
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA78BFA).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.chat_bubble_outline, color: Color(0xFFA78BFA), size: 44),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Dictation arrives in Phase 4',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Live speech-to-text streaming is being wired up. For now, use Capture to record a visit and let Pronote generate the note from your audio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.mic),
                  label: const Text('Open Capture instead'),
                  onPressed: () => context.go('/capture'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
