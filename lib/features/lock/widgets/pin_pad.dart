import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable numeric PIN entry pad: a row of dots that fill as digits are
/// entered, plus a 3×4 keypad. When [length] digits are reached [onCompleted]
/// fires and the internal buffer clears, ready for another attempt.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.title,
    this.errorText,
  });

  final int length;

  /// Called when [length] digits have been entered, THEN the buffer clears.
  final void Function(String pin) onCompleted;

  /// Optional label shown above the dots.
  final String? title;

  /// Shown in the error color under the dots when non-null.
  final String? errorText;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  void _onDigit(String digit) {
    if (_pin.length >= widget.length) return;
    HapticFeedback.lightImpact();
    setState(() => _pin += digit);
    if (_pin.length == widget.length) {
      final completed = _pin;
      // Clear so the pad is ready for another attempt before notifying.
      setState(() => _pin = '');
      widget.onCompleted(completed);
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _Dot(filled: i < _pin.length),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 24,
          child: widget.errorText != null
              ? Text(
                  widget.errorText!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.error),
                )
              : null,
        ),
        const SizedBox(height: 16),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final digit in row)
                _KeyButton(
                  onTap: () => _onDigit(digit),
                  child: Text(
                    digit,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _KeyButton(onTap: null, child: SizedBox.shrink()),
            _KeyButton(
              onTap: () => _onDigit('0'),
              child: Text(
                '0',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            _KeyButton(
              onTap: _onBackspace,
              child: const Icon(Icons.backspace_outlined),
            ),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.filled});
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? scheme.primary : Colors.transparent,
        border: Border.all(
          color: filled ? scheme.primary : scheme.outlineVariant,
          width: 2,
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.onTap, required this.child});
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
