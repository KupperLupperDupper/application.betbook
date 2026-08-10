import 'dart:async';

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
  // Clear any queued/current bars so rapid actions never stack one that lingers.
  messenger.clearSnackBars();

  var handled = false;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? controller;

  controller = messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      // We own dismissal via the timer below. The built-in duration timer is
      // suppressed by the platform when accessible-navigation is on, which is
      // why relying on it left the bar pinned on screen — so we use a long
      // duration and dismiss ourselves.
      duration: const Duration(minutes: 1),
      action: SnackBarAction(
        label: undoLabel,
        onPressed: () {
          if (handled) return;
          handled = true;
          try {
            onUndo();
          } catch (_) {/* restore is best-effort; SnackBarAction still dismisses */}
        },
      ),
    ),
  );

  // Guaranteed auto-dismiss after 4 s regardless of platform timer quirks.
  Timer(const Duration(seconds: 4), () {
    if (handled) return;
    handled = true;
    controller?.close();
  });
}
