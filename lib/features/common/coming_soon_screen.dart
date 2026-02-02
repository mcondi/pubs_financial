import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.emoji,
  });

  final String title;
  final String? subtitle;
  final String? emoji;

  static const _bg = Color.fromRGBO(7, 32, 64, 1);
  static const _cardBlue = Color.fromRGBO(19, 52, 98, 1);

  String _pickEmoji() {
    if (emoji != null && emoji!.trim().isNotEmpty) return emoji!.trim();
    const options = ['🚧', '🛠️', '🧪', '🧠', '✨', '🚀', '👷‍♂️', '🧱', '🧰'];
    return options[math.Random().nextInt(options.length)];
  }

  String _pickLine() {
    const lines = [
      "Cooking this one up…",
      "Not ready yet (but it’s gonna be good).",
      "Under construction. Hard hat recommended.",
      "Hold tight — this feature is on the runway.",
      "This button did something… just not today 😅",
      "Coming soon. Like… actually soon.",
    ];
    return lines[math.Random().nextInt(lines.length)];
  }

  @override
  Widget build(BuildContext context) {
    final bigEmoji = _pickEmoji();
    final line = subtitle?.trim().isNotEmpty == true ? subtitle!.trim() : _pickLine();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBlue.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bigEmoji,
                  style: const TextStyle(fontSize: 72, height: 1.0),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Coming soon",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  line,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 14,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home),
                  label: const Text('Back to main menu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
