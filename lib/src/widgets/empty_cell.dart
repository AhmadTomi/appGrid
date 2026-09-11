import 'package:flutter/widgets.dart';

/// Standardized placeholder rendered when a cell value is null or empty.
class EmptyCell extends StatelessWidget {
  final String placeholder;
  final TextStyle? style;
  final Alignment alignment;

  const EmptyCell({
    super.key,
    this.placeholder = '—',
    this.style,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Text(
        placeholder,
        style: style ?? const TextStyle(color: Color(0x66808080), fontSize: 13),
      ),
    );
  }
}
