import 'package:flutter/material.dart';

/// Standard header widget for feature demonstration pages in the example showcase.
class DemoHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const DemoHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}

/// Helper function to build demo headers.
Widget buildDemoHeader({required String title, required String subtitle}) {
  return DemoHeader(title: title, subtitle: subtitle);
}
