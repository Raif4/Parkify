import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller.dart';
import 'models.dart';
import 'settings_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// Turned on by the home screen so the dock stays off the splash screen.
final ValueNotifier<bool> devDockReady = ValueNotifier<bool>(false);

enum _RS { idle, confirm, busy, ok, fail }

/// Floating developer dock. A small tab sits at the right edge of every
/// screen. Tap it or slide it left to open the panel.
class DevDock extends StatefulWidget {
  const DevDock({super.key});

  @override
  State<DevDock> createState() => _DevDockState();
}

class _DevDockState extends State<DevDock> with SingleTickerProviderStateMixin {
  static const double _panelW = 296;
  static const double _panelH = 345;
  static const double _shift = _panelW + 9;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  final List<_RS> _rs = [_RS.idle, _RS.idle];
  final List<Timer?> _timers = [null, null];

  @override
  void dispose() {
    for (final t in _timers) {
      t?.cancel();
    }
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    final open = _c.value < 0.5;
    _c.animateTo(
      open ? 1.0 : 0.0,
      duration: Duration(milliseconds: open ? 460 : 320),
      curve: open ? Curves.easeOutCubic : Curves.easeInCubic,
    );
  }

  void _close() {
    _c.animateTo(
      0.0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInCubic,
    );
  }

  Future<void> _recal(int i) async {
    if (_rs[i] == _RS.busy) return;
    final s = parkify.slots[i];
    if (s.occupied == true && _rs[i] != _RS.confirm) {
      setState(() => _rs[i] = _RS.confirm);
      _timers[i]?.cancel();
      _timers[i] = Timer(const Duration(seconds: 3), () {
        if (mounted && _rs[i] == _RS.confirm) setState(() => _rs[i] = _RS.idle);
      });
      return;
    }
    _timers[i]?.cancel();
    setState(() => _rs[i] = _RS.busy);
    final ok = await parkify.recalibrateSlot(i);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _rs[i] = ok ? _RS.ok : _RS.fail);
    _timers[i] = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _rs[i] = _RS.idle);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([devDockReady, parkify]),
      builder: (context, _) {
        if (!devDockReady.value || !parkify.showDock) {
          return const SizedBox.shrink();
        }
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            return Stack(children: [
              if (t > 0.02)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _close,
                    child: ColoredBox(color: Colors.black.o(0.38 * t)),
                  ),
                ),
              Align(
                alignment: const Alignment(1, 0.35),
                child: _row(context, t),
              ),
            ]);
          },
        );
      },
    );
  }

  Widget _row(BuildContext context, double t) {
    final panelOpacity =
        Curves.easeOut.transform(((t - 0.1) / 0.9).clamp(0.0, 1.0).toDouble());
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        _c.value = (_c.value - d.delta.dx / _shift).clamp(0.0, 1.0).toDouble();
      },
      onHorizontalDragEnd: (d) {
        final vx = d.velocity.pixelsPerSecond.dx;
        final open = vx.abs() > 400 ? vx < 0 : _c.value > 0.5;
        _c.animateTo(
          open ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      },
      child: Transform.translate(
        offset: Offset(_shift * (1 - t), 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _tab(context, t),
            Opacity(opacity: panelOpacity, child: _panel(context, t)),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, double t) {
    final c = context.colors;
    final link = parkify.overallLink;
    final dot = link == LinkState.live
        ? c.free
        : link == LinkState.connecting
            ? c.paint
            : c.busy;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: SizedBox(
        width: 44,
        height: 110,
        child: Center(
          child: Container(
            width: 26,
            height: 76,
            decoration: BoxDecoration(
              color: Color.lerp(c.panelHi.o(0.85), c.panelHi, t)!,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.line, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: c.shadow,
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(
                  angle: t * math.pi,
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: c.chalk.o(0.5 + 0.5 * t),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stag(double t, int i, Widget child) {
    final p = Interval(
      0.25 + i * 0.12,
      math.min(1.0, 0.65 + i * 0.12),
      curve: Curves.easeOutCubic,
    ).transform(t);
    return Opacity(
      opacity: p,
      child: Transform.translate(
        offset: Offset(0, (1 - p) * 10),
        child: child,
      ),
    );
  }

  Widget _panel(BuildContext context, double t) {
    final c = context.colors;
    final mock = parkify.useMock;
    final n = parkify.slots.length;
    return DefaultTextStyle(
      style: Tx.body.copyWith(color: c.dim),
      child: Container(
        width: _panelW,
        height: _panelH,
        decoration: BoxDecoration(
          color: c.panel,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: c.line, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stag(
                  t,
                  0,
                  Row(children: [
                    Text('Dev tools', style: Tx.h3.copyWith(color: c.chalk)),
                    const Spacer(),
                    if (mock) _chip(context, 'Demo'),
                  ]),
                ),
                const SizedBox(height: 4),
                _stag(
                  t,
                  1,
                  Text(
                    mock
                        ? 'Demo mode: simulation active.'
                        : 'Recalibrate only when slot is empty.',
                    style: Tx.small.copyWith(color: c.dim),
                  ),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < n; i++) ...[
                  _stag(t, 2 + i, _slotRow(context, i)),
                  const SizedBox(height: 10),
                ],
                if (mock) ...[
                  _stag(t, 2 + n, _flipRow(context)),
                  const SizedBox(height: 6),
                ],
                _stag(t, 3 + n, _linkRow(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.signSoft.o(c.isDark ? 0.12 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.signSoft.o(0.4), width: 1.1),
      ),
      child: Text(
        label,
        style: Tx.small.copyWith(
          color: c.signSoft,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _slotRow(BuildContext context, int i) {
    final c = context.colors;
    final s = parkify.slots[i];
    final lost = s.link == LinkState.lost;
    final canUse = !lost;
    final occ = s.occupied == true;
    final color = lost ? c.paint : (occ ? c.busy : c.free);
    final String status;
    if (lost) {
      status = 'Offline';
    } else {
      status = occ ? 'Occupied' : 'Free';
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.deep,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line, width: 1.2),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.o(c.isDark ? 0.14 : 0.10),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.o(0.5), width: 1.3),
          ),
          child: Text(
            '${s.id}',
            style: Tx.h3.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Slot ${s.id}',
                style: Tx.h3.copyWith(fontSize: 14.5, color: c.chalk),
              ),
              const SizedBox(height: 1),
              Text(
                status,
                style: Tx.small.copyWith(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
        _recalButton(context, i, canUse),
      ]),
    );
  }

  Widget _recalButton(BuildContext context, int i, bool canUse) {
    final c = context.colors;
    final st = canUse ? _rs[i] : _RS.idle;
    final Color border;
    final Color fill;
    final Widget child;
    if (st == _RS.confirm) {
      border = c.busy;
      fill = c.busy.o(0.14);
      child = Text(
        'Confirm',
        style: Tx.small.copyWith(
          color: c.busy,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
    } else if (st == _RS.busy) {
      border = c.paint.o(0.5);
      fill = c.paint.o(0.08);
      child = BayLoader(size: 22, color: c.paint);
    } else if (st == _RS.ok) {
      border = c.free;
      fill = c.free.o(0.14);
      child = Icon(Icons.check_rounded, color: c.free, size: 20);
    } else if (st == _RS.fail) {
      border = c.paint;
      fill = c.paint.o(0.12);
      child = Text(
        'Failed',
        style: Tx.small.copyWith(
          color: c.paint,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
    } else {
      border = canUse ? c.signSoft.o(0.6) : c.line;
      fill = Colors.transparent;
      child = Text(
        canUse ? 'Recalibrate' : 'Unavailable',
        style: Tx.small.copyWith(
          color: canUse ? c.signSoft : c.mute,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
    }
    return Pressable(
      scale: 0.94,
      onTap: canUse ? () => _recal(i) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 104,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.3),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey('$i-${st.name}'),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _miniBtn(BuildContext context, String label, VoidCallback onTap) {
    final c = context.colors;
    return Pressable(
      scale: 0.95,
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.panelHi,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.line, width: 1.3),
        ),
        child: Text(
          label,
          style: Tx.small.copyWith(
            color: c.chalk,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _flipRow(BuildContext context) => Row(children: [
        Expanded(
          child: _miniBtn(
            context,
            'Flip slot 1',
            () => parkify.simulateToggle(0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniBtn(
            context,
            'Flip slot 2',
            () => parkify.simulateToggle(1),
          ),
        ),
      ]);

  Widget _linkRow(BuildContext context) {
    final c = context.colors;
    return Pressable(
      scale: 0.98,
      onTap: () {
        _close();
        navKey.currentState?.push(smoothRoute(const SettingsScreen()));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Text(
            'Settings & Dev options',
            style: Tx.small.copyWith(
              color: c.signSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, size: 18, color: c.signSoft),
        ]),
      ),
    );
  }
}
