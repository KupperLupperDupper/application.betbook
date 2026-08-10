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
  // Clear any queued/current snackbars so rapid actions never stack and leave
  // one lingering. `clearSnackBars` removes the queue too (hideCurrentSnackBar
  // only dismisses the visible one).
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 4),
      // Default (fixed) behavior: a floating SnackBar inside the home's Stack
      // can fail to auto-dismiss; fixed anchors to the Scaffold and always does.
      action: SnackBarAction(
        label: undoLabel,
        // Guard the callback: if it threw, SnackBarAction would skip its own
        // dismiss and the bar would stay on screen forever.
        onPressed: () {
          try {
            onUndo();
          } catch (_) {/* restore is best-effort; still dismiss */}
        },
      ),
    ),
  );
}
