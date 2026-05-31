import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/city_map_model.dart';
import '../../models/city_model.dart';
import '../../models/shop_model.dart';

class CityMapView extends StatelessWidget {
  final CityData city;
  final List<CityMapLocation> locations;
  final List<Shop> shops;
  final CityMapLocation? selected;
  final ValueChanged<CityMapLocation> onSelect;

  const CityMapView({
    super.key,
    required this.city,
    required this.locations,
    required this.shops,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.15,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _CityMapPainter())),
                for (final location in locations)
                  _HotspotButton(
                    city: city,
                    location: location,
                    ownedShopCount: shops
                        .where((shop) =>
                            shop.cityId == city.id &&
                            shop.locationName == location.template.name)
                        .length,
                    isSelected: selected?.id == location.id,
                    size: size,
                    onTap: () => onSelect(location),
                  ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: _CityBadge(city: city),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CityBadge extends StatelessWidget {
  final CityData city;
  const _CityBadge({required this.city});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.bg.withAlpha(220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(city.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                city.name,
                style: AppText.display(size: 16, weight: FontWeight.w800),
              ),
              Text(
                city.tier.label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HotspotButton extends StatelessWidget {
  final CityData city;
  final CityMapLocation location;
  final int ownedShopCount;
  final bool isSelected;
  final Size size;
  final VoidCallback onTap;

  const _HotspotButton({
    required this.city,
    required this.location,
    required this.ownedShopCount,
    required this.isSelected,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final left = location.mapPosition.dx * size.width;
    final top = location.mapPosition.dy * size.height;
    final score = location.attractivenessScore(city).round();
    final color = ownedShopCount > 0
        ? AppColors.accent
        : isSelected
            ? AppColors.gold
            : AppColors.primary;

    return Positioned(
      left: left - 34,
      top: top - 44,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 160),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bgCard.withAlpha(238),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color, width: isSelected ? 2 : 1),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(70),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(location.icon, style: const TextStyle(fontSize: 22)),
                    Text(
                      ownedShopCount > 0 ? 'x$ownedShopCount' : '$score',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: const Size(22, 12),
                painter: _PinPainter(color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  final Color color;
  const _PinPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CityMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF10251A), Color(0xFF1F1813), Color(0xFF332315)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    _drawRoad(canvas, [
      Offset(-0.05 * size.width, 0.74 * size.height),
      Offset(0.30 * size.width, 0.55 * size.height),
      Offset(0.63 * size.width, 0.64 * size.height),
      Offset(1.05 * size.width, 0.38 * size.height),
    ]);
    _drawRoad(canvas, [
      Offset(0.20 * size.width, -0.04 * size.height),
      Offset(0.37 * size.width, 0.38 * size.height),
      Offset(0.48 * size.width, 1.06 * size.height),
    ]);

    final blockPaint = Paint()..color = const Color(0xAA2A3B28);
    final roofPaint = Paint()..color = const Color(0xCC493120);
    for (var i = 0; i < 24; i++) {
      final x = ((i * 73) % 310) / 310 * size.width;
      final y = (0.12 + (((i * 41) % 230) / 300)) * size.height;
      final w = 26.0 + (i % 4) * 9;
      final h = 18.0 + (i % 3) * 7;
      _drawIsoBlock(canvas, Offset(x, y), Size(w, h), blockPaint, roofPaint);
    }

    final glow = Paint()
      ..color = AppColors.primary.withAlpha(32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.24),
      math.min(size.width, size.height) * 0.18,
      glow,
    );
  }

  void _drawRoad(Canvas canvas, List<Offset> points) {
    final shadow = Paint()
      ..color = Colors.black.withAlpha(90)
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final road = Paint()
      ..color = const Color(0xFF5A4634)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final line = Paint()
      ..color = AppColors.cream.withAlpha(130)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path.shift(const Offset(0, 4)), shadow);
    canvas.drawPath(path, road);
    canvas.drawPath(path, line);
  }

  void _drawIsoBlock(
    Canvas canvas,
    Offset center,
    Size blockSize,
    Paint wallPaint,
    Paint roofPaint,
  ) {
    final w = blockSize.width;
    final h = blockSize.height;
    final roof = Path()
      ..moveTo(center.dx, center.dy - h / 2)
      ..lineTo(center.dx + w / 2, center.dy)
      ..lineTo(center.dx, center.dy + h / 2)
      ..lineTo(center.dx - w / 2, center.dy)
      ..close();
    final wall = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx - w / 2, center.dy, w, h * 0.9),
      const Radius.circular(4),
    );
    canvas.drawRRect(wall, wallPaint);
    canvas.drawPath(roof, roofPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
