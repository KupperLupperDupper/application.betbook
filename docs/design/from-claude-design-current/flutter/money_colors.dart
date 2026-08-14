import 'package:flutter/material.dart';

/// Profit / loss / neutral semantics. Material 3 has no native slot for these.
///
/// Apply ONLY to net figures (overall P/L, per-site net, chart series,
/// best/worst cards). Individual deposit and withdrawal amounts stay onSurface.
/// Always pair with a +/- sign AND a directional icon — never colour alone.
@immutable
class MoneyColors extends ThemeExtension<MoneyColors> {
  const MoneyColors({
    required this.profit,
    required this.onProfit,
    required this.profitContainer,
    required this.onProfitContainer,
    required this.loss,
    required this.onLoss,
    required this.lossContainer,
    required this.onLossContainer,
    required this.neutral,
    required this.neutralContainer,
  });

  final Color profit, onProfit, profitContainer, onProfitContainer;
  final Color loss, onLoss, lossContainer, onLossContainer;
  final Color neutral, neutralContainer;

  /// profit 5.42:1 · loss 5.11:1 · neutral 6.24:1 against surface #FAF9FC (AA).
  static const light = MoneyColors(
    profit: Color(0xFF0F6E52),
    onProfit: Color(0xFFFFFFFF),
    profitContainer: Color(0xFFB8EBD8),
    onProfitContainer: Color(0xFF002018),
    loss: Color(0xFFB3401A),
    onLoss: Color(0xFFFFFFFF),
    lossContainer: Color(0xFFFFDBCF),
    onLossContainer: Color(0xFF3B0B00),
    neutral: Color(0xFF5A6068),
    neutralContainer: Color(0xFFE3E2E6),
  );

  /// profit 10.9:1 · loss 9.6:1 · neutral 8.1:1 against surface #121318.
  static const dark = MoneyColors(
    profit: Color(0xFF6FD9B3),
    onProfit: Color(0xFF00382A),
    profitContainer: Color(0xFF0B4B38),
    onProfitContainer: Color(0xFFB8EBD8),
    loss: Color(0xFFFFB59A),
    onLoss: Color(0xFF5A1500),
    lossContainer: Color(0xFF7A2A0E),
    onLossContainer: Color(0xFFFFDBCF),
    neutral: Color(0xFFA9AEB6),
    neutralContainer: Color(0xFF34353A),
  );

  /// Colour for a net amount. Exact zero is neutral, never green.
  Color forAmount(num net) =>
      net > 0 ? profit : (net < 0 ? loss : neutral);

  /// trending_up / trending_down / trending_flat — the icon half of the rule.
  IconData iconForAmount(num net) => net > 0
      ? Icons.trending_up
      : (net < 0 ? Icons.trending_down : Icons.trending_flat);

  @override
  MoneyColors copyWith({
    Color? profit, Color? onProfit, Color? profitContainer, Color? onProfitContainer,
    Color? loss, Color? onLoss, Color? lossContainer, Color? onLossContainer,
    Color? neutral, Color? neutralContainer,
  }) => MoneyColors(
        profit: profit ?? this.profit,
        onProfit: onProfit ?? this.onProfit,
        profitContainer: profitContainer ?? this.profitContainer,
        onProfitContainer: onProfitContainer ?? this.onProfitContainer,
        loss: loss ?? this.loss,
        onLoss: onLoss ?? this.onLoss,
        lossContainer: lossContainer ?? this.lossContainer,
        onLossContainer: onLossContainer ?? this.onLossContainer,
        neutral: neutral ?? this.neutral,
        neutralContainer: neutralContainer ?? this.neutralContainer,
      );

  @override
  MoneyColors lerp(ThemeExtension<MoneyColors>? other, double t) {
    if (other is! MoneyColors) return this;
    return MoneyColors(
      profit: Color.lerp(profit, other.profit, t)!,
      onProfit: Color.lerp(onProfit, other.onProfit, t)!,
      profitContainer: Color.lerp(profitContainer, other.profitContainer, t)!,
      onProfitContainer: Color.lerp(onProfitContainer, other.onProfitContainer, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      onLoss: Color.lerp(onLoss, other.onLoss, t)!,
      lossContainer: Color.lerp(lossContainer, other.lossContainer, t)!,
      onLossContainer: Color.lerp(onLossContainer, other.onLossContainer, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      neutralContainer: Color.lerp(neutralContainer, other.neutralContainer, t)!,
    );
  }
}

extension MoneyColorsX on BuildContext {
  MoneyColors get money => Theme.of(this).extension<MoneyColors>()!;
}
