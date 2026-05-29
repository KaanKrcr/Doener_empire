import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _fmt =
    NumberFormat.currency(locale: 'de_DE', symbol: '€', decimalDigits: 2);
final _fmtShort =
    NumberFormat.currency(locale: 'de_DE', symbol: '€', decimalDigits: 0);

class AnimatedMoney extends StatefulWidget {
  final double amount;
  final double fontSize;
  final Color color;
  final bool compact;
  final bool showSign;
  final String? fontFamily;

  const AnimatedMoney({
    super.key,
    required this.amount,
    this.fontSize = 32,
    this.color = Colors.white,
    this.compact = false,
    this.showSign = false,
    this.fontFamily,
  });

  @override
  State<AnimatedMoney> createState() => _AnimatedMoneyState();
}

class _AnimatedMoneyState extends State<AnimatedMoney>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _prev = 0;

  @override
  void initState() {
    super.initState();
    _prev = widget.amount;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: widget.amount, end: widget.amount)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(AnimatedMoney old) {
    super.didUpdateWidget(old);
    if (old.amount != widget.amount) {
      _anim = Tween<double>(begin: _prev, end: widget.amount)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _prev = widget.amount;
      _ctrl.forward(from: 0);
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
      animation: _anim,
      builder: (_, __) {
        final v = _anim.value;
        final prefix = widget.showSign && v >= 0 ? '+' : '';
        final text =
            prefix + (widget.compact ? _fmtShort.format(v) : _fmt.format(v));
        return Text(
          text,
          style: TextStyle(
            fontFamily: widget.fontFamily,
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w800,
            color: widget.color,
            letterSpacing: -0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}
