import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Leichtgewichtiger Konfetti-Burst — reiner CustomPainter, keine externen
/// Pakete, voll offline. Wird über Belohnungs-Momente gelegt (Tagesabschluss
/// mit Gewinn, Mission erfüllt, Trophäe). Spielt einmal ab und verschwindet.
class ConfettiOverlay extends StatefulWidget {
  final int particleCount;
  final Duration duration;
  final List<Color> colors;

  const ConfettiOverlay({
    super.key,
    this.particleCount = 70,
    this.duration = const Duration(milliseconds: 2200),
    this.colors = const [
      AppColors.gold,
      AppColors.secondary,
      AppColors.primary,
      AppColors.accent,
      AppColors.cream,
      AppColors.onion,
    ],
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(
      widget.particleCount,
      (_) => _Particle.random(rng, widget.colors),
    );
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _ConfettiPainter(_particles, _ctrl.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  final double startX; // 0..1 relativ zur Breite
  final double angle; // Abwurfrichtung
  final double speed;
  final double rotationSpeed;
  final double size;
  final Color color;
  final double wobble;

  _Particle({
    required this.startX,
    required this.angle,
    required this.speed,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.wobble,
  });

  factory _Particle.random(Random rng, List<Color> colors) {
    return _Particle(
      startX: 0.3 + rng.nextDouble() * 0.4, // aus der Mitte heraus
      angle: -pi / 2 + (rng.nextDouble() - 0.5) * 1.4, // nach oben gestreut
      speed: 0.55 + rng.nextDouble() * 0.5,
      rotationSpeed: (rng.nextDouble() - 0.5) * 12,
      size: 6 + rng.nextDouble() * 7,
      color: colors[rng.nextInt(colors.length)],
      wobble: rng.nextDouble() * 2 * pi,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0..1

  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const gravity = 1.6;

    for (final p in particles) {
      // Ballistische Bahn: Start aus oberem Drittel, Bogen nach unten.
      final originX = p.startX * size.width;
      final originY = size.height * 0.32;
      final vx = cos(p.angle) * p.speed;
      final vy = sin(p.angle) * p.speed;

      final dx = vx * t * size.width;
      final dy = (vy * t + 0.5 * gravity * t * t) * size.height;
      final wobbleX = sin(t * 6 + p.wobble) * 10;

      final pos = Offset(originX + dx + wobbleX, originY + dy);

      // Ausblenden gegen Ende
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.rotationSpeed * t);
      // Rechteckiges Konfetti-Schnipsel
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
