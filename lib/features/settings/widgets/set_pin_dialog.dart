import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import '../../lock/widgets/pin_pad.dart';

/// Two-step PIN setup: enter, then confirm. Returns the chosen PIN, or null if
/// cancelled. Reuses the shared [PinPad].
Future<String?> showSetPinDialog(BuildContext context, {int length = 4}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _SetPinSheet(length: length),
  );
}

class _SetPinSheet extends StatefulWidget {
  const _SetPinSheet({required this.length});
  final int length;

  @override
  State<_SetPinSheet> createState() => _SetPinSheetState();
}

class _SetPinSheetState extends State<_SetPinSheet> {
  String? _first;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 8,
      ),
      child: PinPad(
        length: widget.length,
        title: _first == null ? l10n.lockSetPin : l10n.lockConfirmPin,
        errorText: _error,
        onCompleted: (pin) {
          if (_first == null) {
            setState(() {
              _first = pin;
              _error = null;
            });
          } else if (_first == pin) {
            Navigator.pop(context, pin);
          } else {
            setState(() {
              _first = null;
              _error = l10n.lockPinMismatch;
            });
          }
        },
      ),
    );
  }
}
