import 'package:flutter/material.dart';

/// Pulsierender Glow-Effekt für die Cash-Karte — wird bei jeder Cash-Änderung
/// kurz aktiv und gibt visuelles Feedback "Geld kommt rein!".
class MoneyPulse extends StatefulWidget {
  final double cash;
  final Widget child;

  const MoneyPulse({
    super.key,
    required this.cash,
    required this.child,
  });

  @override
  State<MoneyPulse> createState() => _MoneyPulseState();
}

class _MoneyPulseState extends State<MoneyPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  double _lastCash = 0;
  bool _wasIncrease = true;

  @override
  void initState() {
    super.initState();
    _lastCash = widget.cash;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(MoneyPulse old) {
    super.didUpdateWidget(old);
    final diff = widget.cash - _lastCash;
    if (diff.abs() > 0.01) {
      _wasIncrease = diff > 0;
      _ctrl.forward(from: 0);
      _lastCash = widget.cash;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        // Glow-Intensität fällt ab
        final glow = (1.0 - _pulse.value) * 0.6;
        final color = _wasIncrease
            ? const Color(0xFF7BC950) // success-grün
            : const Color(0xFFE74C3C); // danger-rot
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: glow > 0.01
                ? [
                    BoxShadow(
                      color: color.withAlpha((glow * 255).round()),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
