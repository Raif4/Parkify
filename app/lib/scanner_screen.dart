import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'lot_screen.dart';
import 'lots.dart';
import 'theme.dart';
import 'widgets.dart';

enum _ScanState { idle, ok, bad }

/// QR scanner: dimmed camera with a centered cut-out.
/// Lot QR codes should contain the text  parkify:nexus-mall
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  final MobileScannerController _cam = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const [BarcodeFormat.qrCode],
  );

  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..forward();
  late final AnimationController _ok = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  _ScanState _state = _ScanState.idle;
  String _badMsg = 'That is not a Parkify lot code. Try another.';
  Lot? _found;
  bool _torch = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _idle.dispose();
    _enter.dispose();
    _ok.dispose();
    _shake.dispose();
    _cam.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_state != _ScanState.idle) return;
    String? raw;
    for (final b in capture.barcodes) {
      if (b.rawValue != null) {
        raw = b.rawValue;
        break;
      }
    }
    if (raw == null) return;
    final v = raw.trim().toLowerCase();
    for (final lot in kLots) {
      if (v.contains(lot.id)) {
        if (lot.status == LotStatus.live) {
          _success(lot);
        } else {
          _reject('${lot.name} is not live yet.');
        }
        return;
      }
    }
    _reject('That is not a Parkify lot code. Try another.');
  }

  void _success(Lot lot) {
    setState(() {
      _found = lot;
      _state = _ScanState.ok;
    });
    HapticFeedback.heavyImpact();
    _cam.stop();
    _ok.forward(from: 0);
    _timer = Timer(const Duration(milliseconds: 1250), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(smoothRoute(LotScreen(lot: lot)));
    });
  }

  void _reject(String message) {
    setState(() {
      _badMsg = message;
      _state = _ScanState.bad;
    });
    HapticFeedback.vibrate();
    _shake.forward(from: 0);
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _state = _ScanState.idle);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = _state == _ScanState.ok
        ? c.free
        : _state == _ScanState.bad
            ? c.busy
            : Colors.white;
    final message = _state == _ScanState.ok
        ? '${_found?.name ?? 'Lot'} found'
        : _state == _ScanState.bad
            ? _badMsg
            : 'Point the camera at the QR code at the entrance.';

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (context, constraints) {
        final side = math.min(constraints.maxWidth * 0.72, 300.0);
        final msgTop = constraints.maxHeight * 0.42 + side / 2 + 38;
        return Stack(children: [
          Positioned.fill(
            child: MobileScanner(controller: _cam, onDetect: _onDetect),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([_idle, _enter, _ok, _shake]),
                builder: (_, _) => CustomPaint(
                  painter: _ScanPainter(
                    idle: _idle.value,
                    enter: Curves.easeOutCubic.transform(_enter.value),
                    ok: _ok.value,
                    shake: _shake.value,
                    color: color,
                    laserColor: c.paint,
                    successColor: c.free,
                    scanning: _state == _ScanState.idle,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: SizedBox(
                  height: 46,
                  child: Row(children: [
                    RoundButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Scan lot QR',
                          style: Tx.h3.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    RoundButton(
                      icon: _torch
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      onTap: () {
                        _cam.toggleTorch();
                        setState(() => _torch = !_torch);
                      },
                    ),
                  ]),
                ),
              ),
            ),
          ),
          Positioned(
            top: msgTop,
            left: 24,
            right: 24,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(a),
                    child: child,
                  ),
                ),
                child: Container(
                  key: ValueKey(_state),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: c.panel.o(0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _state == _ScanState.idle
                          ? c.line
                          : color.o(0.7),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.o(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Tx.h3.copyWith(
                      fontSize: 14.5,
                      color: _state == _ScanState.idle ? c.chalk : color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]);
      }),
    );
  }
}

class _ScanPainter extends CustomPainter {
  _ScanPainter({
    required this.idle,
    required this.enter,
    required this.ok,
    required this.shake,
    required this.color,
    required this.laserColor,
    required this.successColor,
    required this.scanning,
  });

  final double idle;
  final double enter;
  final double ok;
  final double shake;
  final Color color;
  final Color laserColor;
  final Color successColor;
  final bool scanning;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width * 0.72, 300.0);
    final scale =
        1.0 + 0.10 * (1 - enter) + 0.05 * math.sin(ok * math.pi);
    final dx = math.sin(shake * math.pi * 6) * 12 * (1 - shake);
    final c = Offset(size.width / 2 + dx, size.height * 0.42);
    final rect =
        Rect.fromCenter(center: c, width: side * scale, height: side * scale);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(30));

    // Dark frosted overlay with cut-out
    final dim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rr);
    canvas.drawPath(
      dim,
      Paint()..color = Colors.black.o(0.62 * enter + 0.12 * ok),
    );
    if (ok > 0) {
      canvas.drawRRect(rr, Paint()..color = successColor.o(0.10 * ok));
    }

    // Corner brackets
    final b = 4 * math.sin(idle * 2 * math.pi) * (1 - ok);
    final r = rect.inflate(b);
    const len = 40.0;
    const rad = 30.0;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.top + len)
        ..lineTo(r.left, r.top + rad)
        ..arcToPoint(Offset(r.left + rad, r.top),
            radius: const Radius.circular(rad))
        ..lineTo(r.left + len, r.top),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r.right - len, r.top)
        ..lineTo(r.right - rad, r.top)
        ..arcToPoint(Offset(r.right, r.top + rad),
            radius: const Radius.circular(rad))
        ..lineTo(r.right, r.top + len),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r.right, r.bottom - len)
        ..lineTo(r.right, r.bottom - rad)
        ..arcToPoint(Offset(r.right - rad, r.bottom),
            radius: const Radius.circular(rad))
        ..lineTo(r.right - len, r.bottom),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r.left + len, r.bottom)
        ..lineTo(r.left + rad, r.bottom)
        ..arcToPoint(Offset(r.left, r.bottom - rad),
            radius: const Radius.circular(rad))
        ..lineTo(r.left, r.bottom - len),
      p,
    );

    // Laser scan line
    if (scanning && ok == 0) {
      final t = 0.5 - 0.5 * math.cos(idle * 2 * math.pi);
      final y = rect.top + 22 + (rect.height - 44) * t;
      canvas.save();
      canvas.clipRRect(rr);
      final glow = Rect.fromLTWH(rect.left, y - 56, rect.width, 56);
      canvas.drawRect(
        glow,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [laserColor.o(0), laserColor.o(0.25)],
          ).createShader(glow),
      );
      canvas.drawLine(
        Offset(rect.left + 18, y),
        Offset(rect.right - 18, y),
        Paint()
          ..color = laserColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }

    // Success checkmark animation
    if (ok > 0) {
      final e = Curves.easeOutCubic.transform(ok);
      canvas.drawCircle(
        c,
        side * 0.16 + side * 0.5 * e,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = successColor.o((1 - e) * 0.6),
      );
      final badge = Curves.easeOutBack.transform(math.min(1.0, ok * 2.2));
      canvas.drawCircle(
        c,
        side * 0.17 * badge,
        Paint()..color = successColor.o(0.2),
      );
      final chk = Path()
        ..moveTo(c.dx - side * 0.09, c.dy + side * 0.005)
        ..lineTo(c.dx - side * 0.02, c.dy + side * 0.075)
        ..lineTo(c.dx + side * 0.1, c.dy - side * 0.07);
      final m = chk.computeMetrics().first;
      final prog = Curves.easeOut
          .transform(((ok - 0.25) / 0.45).clamp(0.0, 1.0).toDouble());
      canvas.drawPath(
        m.extractPath(0, m.length * prog),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = successColor,
      );
    }
  }

  @override
  bool shouldRepaint(_ScanPainter o) => true;
}
