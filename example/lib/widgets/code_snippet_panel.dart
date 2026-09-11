import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Right-hand documentation code preview and copy panel.
class CodeSnippetPanel extends StatefulWidget {
  final String title;
  final String code;

  const CodeSnippetPanel({
    super.key,
    required this.title,
    required this.code,
  });

  @override
  State<CodeSnippetPanel> createState() => _CodeSnippetPanelState();
}

class _CodeSnippetPanelState extends State<CodeSnippetPanel> {
  bool _copied = false;

  void _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF18181B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Copy Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF27272A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.code, color: Colors.lightBlueAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.title} • Code Snippet',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _copied ? Colors.green : const Color(0xFF3F3F46),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () => _copyCode(widget.code),
                  icon: Icon(_copied ? Icons.check : Icons.copy, size: 14),
                  label: Text(_copied ? 'Copied!' : 'Copy Code', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          // Scrollable Code Display
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                widget.code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  color: Color(0xFFE4E4E7),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
