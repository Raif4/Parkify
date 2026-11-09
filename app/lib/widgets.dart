import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'theme.dart';

/// App-wide navigator key (used by the in-app banner).
final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

/// Shrinks on press, springs back, light haptic tick.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
    this.haptic = true,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: enabled
          ? () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: Duration(milliseconds: _down ? 90 : 280),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// One-time staggered entrance (used on the home screen).
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.index = 0, this.dy = 18});
  final Widget child;
  final int index;
  final double dy;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(Duration(milliseconds: 70 * widget.index), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _a.value) * widget.dy),
          child: child,
        ),
      ),
    );
  }
}

/// Sweeping highlight for skeleton placeholders.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) {
          final t = _c.value;
          return LinearGradient(
            begin: Alignment(-2.0 + 3.0 * t, -0.3),
            end: Alignment(-1.0 + 3.0 * t, 0.3),
            colors: [c.panel, c.panelHi, c.panel],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(rect);
        },
        child: child,
      ),
    );
  }
}

class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.h = 16, this.w, this.r = 16});
  final double h;
  final double? w;
  final double r;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: c.panelHi,
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
}

/// Loader: an amber paint stroke chasing around a parking-bay outline.
class BayLoader extends StatefulWidget {
  const BayLoader({super.key, this.size = 44, this.color});
  final double size;
  final Color? color;

  @override
  State<BayLoader> createState() => _BayLoaderState();
}

class _BayLoaderState extends State<BayLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? context.colors.paint;
    final trackColor = context.colors.line.o(0.6);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _BayLoaderPainter(_c.value, activeColor, trackColor),
        ),
      ),
    );
  }
}

class _BayLoaderPainter extends CustomPainter {
  _BayLoaderPainter(this.t, this.color, this.trackColor);
  final double t;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = math.max(2.5, size.width * 0.075);
    final rect = Rect.fromLTWH(
      size.width * 0.2,
      size.height * 0.08,
      size.width * 0.6,
      size.height * 0.84,
    );
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(size.width * 0.14),
        ),
      );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = trackColor,
    );
    final m = path.computeMetrics().first;
    final len = m.length;
    final seg = len * 0.32;
    final start = t * len;
    final end = start + seg;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..color = color;
    if (end <= len) {
      canvas.drawPath(m.extractPath(start, end), p);
    } else {
      canvas.drawPath(m.extractPath(start, len), p);
      canvas.drawPath(m.extractPath(0, end - len), p);
    }
  }

  @override
  bool shouldRepaint(_BayLoaderPainter o) =>
      o.t != t || o.color != color || o.trackColor != trackColor;
}

/// Live indicator: dot with an expanding pulsing ring.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color, this.size = 8});
  final Color color;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.size * 2.4,
        height: widget.size * 2.4,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            painter: _PulsePainter(_c.value, widget.color, widget.size),
          ),
        ),
      );
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.t, this.color, this.dot);
  final double t;
  final Color color;
  final double dot;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = dot / 2 + (dot * 1.2 - dot / 2) * Curves.easeOut.transform(t);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = color.o((1 - t) * 0.55),
    );
    canvas.drawCircle(c, dot / 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PulsePainter o) => o.t != t || o.color != color;
}

/// The Parkify signature mark: a sapphire badge with an inset border and white P.
class SignTile extends StatelessWidget {
  const SignTile({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            c.sign,
            Color.lerp(c.sign, const Color(0xFF1E3A8A), 0.25)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: c.sign.o(0.35),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(size * 0.08),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.18),
          border: Border.all(color: Colors.white.o(0.92), width: size * 0.045),
        ),
        alignment: Alignment.center,
        child: Text(
          'P',
          style: TextStyle(
            fontFamily: 'Overpass',
            fontWeight: FontWeight.w800,
            fontSize: size * 0.56,
            height: 1.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Refined card panel with frosted borders and ambient shadow.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 22,
    this.border,
    this.glow,
    this.color,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? border;
  final Color? glow;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cardBg = color ?? c.panel;
    final borderColor = border ?? c.line;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: glow != null
            ? [
                BoxShadow(
                  color: glow!.o(c.isDark ? 0.22 : 0.15),
                  blurRadius: 26,
                  spreadRadius: -2,
                )
              ]
            : [
                BoxShadow(
                  color: c.shadow,
                  blurRadius: c.isDark ? 22 : 14,
                  offset: const Offset(0, 5),
                  spreadRadius: -3,
                )
              ],
      ),
      child: child,
    );
  }
}

/// Polished rounded action button.
class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 46,
  });
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      scale: 0.88,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c.panelHi,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: c.line, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: c.chalk, size: 21),
      ),
    );
  }
}

/// Tactile custom animated switch.
class PkSwitch extends StatelessWidget {
  const PkSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.onIcon = Icons.notifications_active_rounded,
    this.offIcon = Icons.notifications_none_rounded,
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData onIcon;
  final IconData offIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      scale: 0.9,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        width: 60,
        height: 34,
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? c.sign : c.panelHi,
          border: Border.all(color: value ? c.sign : c.line, width: 1.2),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: c.sign.o(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  )
                ]
              : const [],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? Colors.white : c.dim,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.o(0.18),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Icon(
                value ? onIcon : offIcon,
                key: ValueKey(value),
                size: 14.5,
                color: value ? c.sign : (c.isDark ? c.asphalt : Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Elevated sliding tab segmented controller.
class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(builder: (context, constraints) {
      final seg = (constraints.maxWidth - 8 - 2.4) / labels.length;
      return Container(
        height: 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: c.panelHi,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: c.line, width: 1.2),
        ),
        child: Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            left: seg * index,
            top: 0,
            bottom: 0,
            width: seg,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    c.sign,
                    Color.lerp(c.sign, const Color(0xFF1D4ED8), 0.2)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: c.sign.o(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Pressable(
                  scale: 0.97,
                  onTap: () => onChanged(i),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 240),
                      style: Tx.h3.copyWith(
                        color: i == index ? Colors.white : c.dim,
                        fontWeight:
                            i == index ? FontWeight.w700 : FontWeight.w600,
                      ),
                      child: Text(labels[i]),
                    ),
                  ),
                ),
              ),
          ]),
        ]),
      );
    });
  }
}

/// Rebuilds its child every second (for live timers).
class TickBuilder extends StatefulWidget {
  const TickBuilder({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  State<TickBuilder> createState() => _TickBuilderState();
}

class _TickBuilderState extends State<TickBuilder> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// Live status pill with glowing pulse dot.
class LivePill extends StatelessWidget {
  const LivePill({super.key, required this.link, this.demo = false});
  final LinkState link;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final showDemo = demo && link == LinkState.live;
    final color = showDemo
        ? c.signSoft
        : link == LinkState.live
            ? c.free
            : link == LinkState.connecting
                ? c.paint
                : c.busy;
    final label = showDemo
        ? 'Demo'
        : link == LinkState.live
            ? 'Live'
            : link == LinkState.connecting
                ? 'Connecting'
                : 'Offline';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      padding: const EdgeInsets.fromLTRB(9, 5, 13, 5),
      decoration: BoxDecoration(
        color: color.o(c.isDark ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.o(c.isDark ? 0.45 : 0.35), width: 1.2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        link == LinkState.lost
            ? SizedBox(
                width: 18,
                child: Center(
                  child: Container(
                    width: 7.5,
                    height: 7.5,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ),
              )
            : PulseDot(color: color, size: 7.5),
        const SizedBox(width: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            label,
            key: ValueKey(label),
            style: Tx.small.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
      ]),
    );
  }
}

/// Lot monogram tile (initials on a tinted rounded square).
class MonoTile extends StatelessWidget {
  const MonoTile({
    super.key,
    required this.initials,
    required this.color,
    this.size = 52,
    this.muted = false,
  });
  final String initials;
  final Color color;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = muted ? Color.lerp(color, c.mute, 0.55)! : color;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: base.o(c.isDark ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: base.o(c.isDark ? 0.45 : 0.35), width: 1.4),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Overpass',
          fontWeight: FontWeight.w800,
          fontSize: initials.length > 1 ? size * 0.35 : size * 0.44,
          height: 1.0,
          letterSpacing: -0.5,
          color: base,
        ),
      ),
    );
  }
}

/// Polished button: filled (sapphire gradient) or outlined.
class PkButton extends StatelessWidget {
  const PkButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = false,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: filled
              ? LinearGradient(
                  colors: [
                    c.sign,
                    Color.lerp(c.sign, const Color(0xFF1E3A8A), 0.2)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: filled ? null : c.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: filled ? c.sign : c.line,
            width: 1.3,
          ),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: c.sign.o(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: c.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: filled ? Colors.white : c.chalk,
            ),
            const SizedBox(width: 9),
          ],
          Text(
            label,
            style: Tx.h3.copyWith(
              fontSize: 15.5,
              color: filled ? Colors.white : c.chalk,
            ),
          ),
        ]),
      ),
    );
  }
}

/// Road-paint style dashed line with champagne amber default.
class DashedLine extends StatelessWidget {
  const DashedLine({
    super.key,
    this.color,
    this.dash = 14,
    this.gap = 10,
    this.stroke = 3,
    this.progress = 1,
  });
  final Color? color;
  final double dash;
  final double gap;
  final double stroke;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? context.colors.paint;
    return SizedBox.expand(
      child: CustomPaint(
        painter: _DashPainter(activeColor, dash, gap, stroke, progress),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.dash, this.gap, this.stroke, this.progress);
  final Color color;
  final double dash;
  final double gap;
  final double stroke;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final end = size.width * progress;
    final y = size.height / 2;
    var x = 0.0;
    while (x < end) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + dash, end), y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter o) =>
      o.progress != progress || o.color != color;
}

/// In-app banner (drops smoothly from the top and auto-dismisses).
class Toast {
  static OverlayEntry? _entry;

  static void show(
    GlobalKey<NavigatorState> key, {
    required String title,
    required String body,
    Color? color,
    IconData icon = Icons.check_circle_rounded,
  }) {
    final overlay = key.currentState?.overlay;
    if (overlay == null) return;
    _entry?.remove();
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (ctx) {
        final activeColor = color ?? ctx.colors.free;
        return _Banner(
          title: title,
          body: body,
          color: activeColor,
          icon: icon,
          onDone: () {
            if (_entry == e) _entry = null;
            e.remove();
          },
        );
      },
    );
    _entry = e;
    overlay.insert(e);
  }
}

class _Banner extends StatefulWidget {
  const _Banner({
    required this.title,
    required this.body,
    required this.color,
    required this.icon,
    required this.onDone,
  });
  final String title;
  final String body;
  final Color color;
  final IconData icon;
  final VoidCallback onDone;

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeInCubic,
  );
  Timer? _t;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _c.forward();
    _t = Timer(const Duration(milliseconds: 3800), _close);
  }

  Future<void> _close() async {
    _t?.cancel();
    if (!mounted) return;
    await _c.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1.6),
          end: Offset.zero,
        ).animate(_curve),
        child: FadeTransition(
          opacity: _c,
          child: Material(
            type: MaterialType.transparency,
            child: GestureDetector(
              onTap: _close,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.panelHi,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.color.o(0.55), width: 1.3),
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow,
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.color.o(c.isDark ? 0.16 : 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: Tx.h3.copyWith(color: c.chalk),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.body,
                          style: Tx.small.copyWith(color: c.dim),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
