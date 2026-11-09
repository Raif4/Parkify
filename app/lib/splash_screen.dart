import 'dart:async';

import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// One orchestrated opening: the sign drops in, the name appears,
/// an amber lane line paints itself underneath.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(smoothRoute(const HomeScreen()));
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  double _iv(double a, double b, Curve curve) =>
      Interval(a, b, curve: curve).transform(_c.value);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.asphalt,
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final sign = _iv(0.0, 0.4, Curves.easeOutBack);
            final name = _iv(0.3, 0.6, Curves.easeOutCubic);
            final line = _iv(0.5, 0.85, Curves.easeInOut);
            final tag = _iv(0.7, 1.0, Curves.easeOut);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(0, (1 - sign) * -70),
                  child: Opacity(
                    opacity: sign.clamp(0.0, 1.0).toDouble(),
                    child: const SignTile(size: 100),
                  ),
                ),
                const SizedBox(height: 24),
                Opacity(
                  opacity: name.clamp(0.0, 1.0).toDouble(),
                  child: Transform.translate(
                    offset: Offset(0, (1 - name) * 12),
                    child: Text(
                      'Parkify',
                      style: Tx.display.copyWith(color: c.chalk),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 150,
                  height: 4,
                  child: DashedLine(
                    color: c.paint,
                    dash: 14,
                    gap: 10,
                    stroke: 3.5,
                    progress: line,
                  ),
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: tag.clamp(0.0, 1.0).toDouble(),
                  child: Text(
                    'Find parking before you arrive.',
                    style: Tx.small.copyWith(color: c.dim),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
