import 'package:flutter/material.dart';

/// The custom numeric keypad shared by the full editor and the quick-add sheet.
/// Emits `'0'..'9'`, `'dot'`, and `'back'`. The OS keyboard is never summoned
/// for amount entry.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    required this.decimalSeparator,
    required this.onTap,
  });

  final String decimalSeparator;
  final void Function(String key) onTap;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['dot', '0', 'back'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in rows)
            Row(
              children: [
                for (final key in row)
                  Expanded(child: _buildKey(context, key)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildKey(BuildContext context, String key) {
    final theme = Theme.of(context);
    Widget label;
    if (key == 'back') {
      label = const Icon(Icons.backspace_outlined);
    } else if (key == 'dot') {
      label = Text(decimalSeparator, style: theme.textTheme.titleLarge);
    } else {
      label = Text(key, style: theme.textTheme.titleLarge);
    }
    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: 56,
        child: InkWell(
          onTap: () => onTap(key),
          borderRadius: BorderRadius.circular(14),
          child: Center(child: label),
        ),
      ),
    );
  }
}
