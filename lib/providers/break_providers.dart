import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-only "reveal totals" flag used by the hide-totals break behaviour
/// (NOTIFICATIONS_HANDOFF §5). While a break is active the app's running-score
/// figures rest as an em dash; tapping "Show totals" flips this to `true` for
/// the current session only. It deliberately does not persist — a new launch
/// (or the break ending) returns totals to their normal state without a stored
/// override to clean up.
final showTotalsProvider = StateProvider<bool>((ref) => false);
