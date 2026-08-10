import 'package:flutter/material.dart';

/// Shows a "deleted — Undo" SnackBar on [messenger].
///
/// Deletes are applied immediately; the SnackBar offers to restore. Callers
/// that navigate away (e.g. delete-from-detail) must capture the messenger
/// with `ScaffoldMessenger.of(context)` *before* popping, since the messenger
/// lives above the router and survives the route change.
void showUndoSnackBar(
  ScaffoldMessengerState messenger, {
  required String message,
  required String undoLabel,
  required VoidCallback onUndo,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: undoLabel, onPressed: onUndo),
      ),
    );
}
