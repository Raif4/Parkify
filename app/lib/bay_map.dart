import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

/// Top-down view of the monitored bays. Cars park in and drive out
/// as slot state changes. This is Parkify's signature element.
class BayMap extends StatelessWidget {
  const BayMap({super.key, required this.slots});
  final List<SlotInfo> slots;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 218,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.deep,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.line, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(children: [
        Positioned(
          left: 20,
          right: 20,
          bottom: 16,
          height: 4,
          child: DashedLine(
            color: c.paint.o(0.9),
            dash: 18,
            gap: 12,
            stroke: 3.5,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
          child: Row(children: [
            for (var i = 0; i < slots.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _Bay(slot: slots[i], index: i),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _Bay extends StatelessWidget {
  const _Bay({required this.slot, required this.index});
  final SlotInfo slot;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final occ = slot.occupied == true;
    final unknown = slot.occupied == null;
    final lost = slot.link == LinkState.lost;
    final tint = lost ? c.paint : (occ ? c.busy : c.free);
    final sideColor = c.isDark
        ? Colors.white.o(0.5)
        : const Color(0xFF1E293B).o(0.4);
    final side = BorderSide(color: sideColor, width: 2.8);

    final car1Color = c.isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF1E3A8A);
    final car2Color = c.isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF2563EB);

    return LayoutBuilder(builder: (context, constraints) {
      final carW = (constraints.maxWidth * 0.56).clamp(44.0, 72.0).toDouble();
      final carH = carW * 1.7;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        decoration: BoxDecoration(
          color: unknown ? Colors.transparent : tint.o(0.08),
          border: Border(left: side, top: side, right: side),
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          Align(
            alignment: const Alignment(0, -0.35),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: occ ? 0 : 1,
              child: Text(
                '${slot.id}',
                style: Tx.big.copyWith(
                  fontSize: 54,
                  color: (c.isDark ? Colors.white : c.chalk).o(0.22),
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: (constraints.maxWidth - carW) / 2,
            width: carW,
            height: carH,
            child: AnimatedSlide(
              offset: occ ? Offset.zero : const Offset(0, 1.8),
              duration: const Duration(milliseconds: 850),
              curve: occ ? Curves.easeOutBack : Curves.easeInCubic,
              child: CustomPaint(
                painter: _CarPainter(
                  index == 0 ? car1Color : car2Color,
                  headlightColor: c.paint,
                  taillightColor: c.busy,
                ),
              ),
            ),
          ),
        ]),
      );
    });
  }
}

class _CarPainter extends CustomPainter {
  _CarPainter(
    this.body, {
    required this.headlightColor,
    required this.taillightColor,
  });

  final Color body;
  final Color headlightColor;
  final Color taillightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft ground contact shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 6, w, h),
        Radius.circular(w * 0.28),
      ),
      Paint()
        ..color = Colors.black.o(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Side mirrors
    final mirror = Paint()..color = body;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.07, h * 0.3, w * 0.12, h * 0.07),
        const Radius.circular(3),
      ),
      mirror,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.95, h * 0.3, w * 0.12, h * 0.07),
        const Radius.circular(3),
      ),
      mirror,
    );

    // Car Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(w * 0.28),
      ),
      mirror,
    );

    // Cabin roof
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.25, w * 0.76, h * 0.5),
        Radius.circular(w * 0.2),
      ),
      Paint()..color = Color.lerp(body, Colors.black, 0.22)!,
    );

    // Glass windshields
    final glass = Paint()..color = const Color(0xFF131C31);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.2, h * 0.27)
        ..lineTo(w * 0.8, h * 0.27)
        ..lineTo(w * 0.74, h * 0.4)
        ..lineTo(w * 0.26, h * 0.4)
        ..close(),
      glass,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.26, h * 0.61)
        ..lineTo(w * 0.74, h * 0.61)
        ..lineTo(w * 0.8, h * 0.73)
        ..lineTo(w * 0.2, h * 0.73)
        ..close(),
      glass,
    );

    // Headlights
    final head = Paint()..color = headlightColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.025, w * 0.24, h * 0.05),
        const Radius.circular(3),
      ),
      head,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.66, h * 0.025, w * 0.24, h * 0.05),
        const Radius.circular(3),
      ),
      head,
    );

    // Taillights
    final tail = Paint()..color = taillightColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.925, w * 0.24, h * 0.04),
        const Radius.circular(3),
      ),
      tail,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.66, h * 0.925, w * 0.24, h * 0.04),
        const Radius.circular(3),
      ),
      tail,
    );
  }

  @override
  bool shouldRepaint(_CarPainter o) =>
      o.body != body ||
      o.headlightColor != headlightColor ||
      o.taillightColor != taillightColor;
}
