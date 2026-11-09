import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bay_map.dart';
import 'controller.dart';
import 'lots.dart';
import 'models.dart';
import 'settings_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class LotScreen extends StatefulWidget {
  const LotScreen({super.key, required this.lot});
  final Lot lot;

  @override
  State<LotScreen> createState() => _LotScreenState();
}

class _LotScreenState extends State<LotScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.asphalt,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: ListenableBuilder(
              listenable: parkify,
              builder: (context, _) => Row(children: [
                RoundButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.lot.name,
                          style: Tx.h2.copyWith(color: c.chalk)),
                      Text(widget.lot.city,
                          style: Tx.small.copyWith(color: c.dim)),
                    ],
                  ),
                ),
                LivePill(link: parkify.overallLink, demo: parkify.useMock),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Segmented(
              labels: const ['Live', 'History'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.03),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: _tab == 0
                  ? _LiveTab(key: const ValueKey('live'), lot: widget.lot)
                  : const _HistoryTab(key: ValueKey('history')),
            ),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- Live

class _LiveTab extends StatelessWidget {
  const _LiveTab({super.key, required this.lot});
  final Lot lot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListenableBuilder(
      listenable: parkify,
      builder: (context, _) {
        if (parkify.loading) return const _LiveSkeleton();
        final free = parkify.freeCount;
        final n = parkify.slots.length;
        final zones = parkify.slots.map((s) => s.zone).join(' and ');
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                transitionBuilder: (child, a) => ScaleTransition(
                  scale: Tween<double>(begin: 0.7, end: 1.0).animate(a),
                  child: FadeTransition(opacity: a, child: child),
                ),
                child: Text(
                  '$free',
                  key: ValueKey(free),
                  style: Tx.big.copyWith(
                    color: free == 0
                        ? c.busy
                        : (c.isDark ? Colors.white : c.chalk),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'of $n slots free',
                  style: Tx.h3.copyWith(color: c.dim),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            if (lot.address != null)
              Text(lot.address!, style: Tx.small.copyWith(color: c.dim)),
            if (lot.hours != null)
              Text('Open ${lot.hours!}',
                  style: Tx.small.copyWith(color: c.dim)),
            Text('Monitoring $zones', style: Tx.small.copyWith(color: c.dim)),
            TickBuilder(
              builder: (_) {
                final t = parkify.lastUpdate;
                if (t == null) return const SizedBox.shrink();
                return Text(
                  'Updated ${ago(t)}',
                  style: Tx.small.copyWith(color: c.mute),
                );
              },
            ),
            const SizedBox(height: 16),
            BayMap(slots: parkify.slots),
            const SizedBox(height: 22),
            for (var i = 0; i < parkify.slots.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SlotCard(
                  slot: parkify.slots[i],
                  notify: parkify.notify[i],
                  hasIp: true,
                  onNotify: () => parkify.toggleNotify(i),
                ),
              ),
            const SizedBox(height: 4),
            PkButton(
              label: 'Open in Maps',
              icon: Icons.near_me_rounded,
              onTap: () => openInMaps(lot),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'Alerts appear while the app is open. Each alert fires once.',
                style: Tx.small.copyWith(color: c.mute),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LiveSkeleton extends StatelessWidget {
  const _LiveSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
      children: [
        const Shimmer(
          child: Column(children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Skeleton(h: 60, w: 190, r: 14),
            ),
            SizedBox(height: 16),
            Skeleton(h: 218, r: 28),
            SizedBox(height: 22),
            Skeleton(h: 150, r: 22),
            SizedBox(height: 14),
            Skeleton(h: 150, r: 22),
          ]),
        ),
        const SizedBox(height: 22),
        Center(
          child: Column(children: [
            const BayLoader(size: 38),
            const SizedBox(height: 8),
            Text(
              'Connecting to the sensors',
              style: Tx.small.copyWith(color: context.colors.mute),
            ),
          ]),
        ),
      ],
    );
  }
}

class SlotCard extends StatefulWidget {
  const SlotCard({
    super.key,
    required this.slot,
    required this.notify,
    required this.hasIp,
    required this.onNotify,
  });
  final SlotInfo slot;
  final bool notify;
  final bool hasIp;
  final VoidCallback onNotify;

  @override
  State<SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<SlotCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didUpdateWidget(SlotCard old) {
    super.didUpdateWidget(old);
    if (old.slot.occupied != null &&
        old.slot.occupied != widget.slot.occupied) {
      _flash.forward(from: 0);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = widget.slot;
    final occ = s.occupied == true;
    final lost = s.link == LinkState.lost;
    final color = lost ? c.paint : (occ ? c.busy : c.free);
    final label = lost ? 'Offline' : (occ ? 'Occupied' : 'Free');

    return Panel(
      radius: 24,
      border: color.o(c.isDark ? 0.45 : 0.35),
      glow: color,
      padding: const EdgeInsets.all(18),
      child: Column(children: [
        Row(children: [
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: -35,
                top: -35,
                width: 120,
                height: 120,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _flash,
                    builder: (_, _) => CustomPaint(
                      painter: _FlashPainter(_flash.value, color),
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.o(c.isDark ? 0.14 : 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: color.o(c.isDark ? 0.55 : 0.4),
                    width: 1.6,
                  ),
                ),
                child: Text(
                  '${s.id}',
                  style: Tx.h2.copyWith(color: color),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Slot ${s.id}', style: Tx.h3.copyWith(color: c.chalk)),
                const SizedBox(height: 2),
                Text(
                  '${s.zone}, ${s.place}',
                  style: Tx.small.copyWith(color: c.dim),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: color.o(c.isDark ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.o(c.isDark ? 0.45 : 0.35),
                width: 1.2,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, a) => ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1.0).animate(a),
                child: FadeTransition(opacity: a, child: child),
              ),
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
          ),
        ]),
        const SizedBox(height: 14),
        Container(height: 1.2, color: c.line),
        const SizedBox(height: 14),
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _footer(context, s, occ, lost, color),
          ),
        ),
      ]),
    );
  }

  Widget _footer(
    BuildContext context,
    SlotInfo s,
    bool occ,
    bool lost,
    Color color,
  ) {
    final c = context.colors;
    if (lost) {
      return Row(
        key: const ValueKey('lost'),
        children: [
          BayLoader(size: 30, color: c.paint),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.hasIp
                  ? 'No signal from slot ${s.id}. Check the disc is powered and on the hotspot.'
                  : 'No address set for slot ${s.id}.',
              style: Tx.small.copyWith(color: c.dim),
            ),
          ),
          if (!widget.hasIp)
            Pressable(
              onTap: () => Navigator.of(context)
                  .push(smoothRoute(const SettingsScreen())),
              child: Text(
                'Set up sensor',
                style: Tx.small.copyWith(
                  color: c.signSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      );
    }
    final since = s.since;
    return Column(
      key: ValueKey(occ),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.timer_outlined, size: 18, color: color),
          const SizedBox(width: 8),
          TickBuilder(
            builder: (_) => Text(
              since == null
                  ? 'Waiting for first reading'
                  : '${occ ? 'Occupied' : 'Free'} for ${fmtDur(DateTime.now().difference(since))}',
              style: Tx.body.copyWith(color: c.chalk),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        if (occ)
          Row(children: [
            Expanded(
              child: Text(
                'Notify me when it frees up',
                style: Tx.body.copyWith(color: c.dim),
              ),
            ),
            PkSwitch(value: widget.notify, onChanged: (_) => widget.onNotify()),
          ])
        else
          Row(children: [
            Icon(Icons.check_circle_rounded, size: 18, color: c.free),
            const SizedBox(width: 8),
            Text(
              'Available now',
              style: Tx.body.copyWith(color: c.chalk),
            ),
          ]),
      ],
    );
  }
}

class _FlashPainter extends CustomPainter {
  _FlashPainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final e = Curves.easeOut.transform(t);
    canvas.drawCircle(
      size.center(Offset.zero),
      26 + 34 * e,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color.o((1 - e) * 0.7),
    );
  }

  @override
  bool shouldRepaint(_FlashPainter o) => o.t != t || o.color != color;
}

// ------------------------------------------------------------- History

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({super.key});

  Color _slotColor(BuildContext context, int id) {
    final c = context.colors;
    return id == 1 ? c.sign : c.paint;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListenableBuilder(
      listenable: parkify,
      builder: (context, _) {
        if (parkify.loading) return const _LiveSkeleton();
        final avg = parkify.avgStay;
        final stays = parkify.stays;
        final recent =
            stays.length > 8 ? stays.sublist(stays.length - 8) : stays;
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
          children: [
            if (parkify.useMock)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Simulated data',
                  style: Tx.small.copyWith(color: c.mute),
                ),
              ),
            Row(children: [
              Expanded(
                child: _Stat(
                  label: 'Average time until free',
                  value: avg == null ? 'Not enough data' : fmtDur(avg),
                  small: avg == null,
                  sub: avg == null
                      ? 'Needs 2 completed stays'
                      : 'across ${stays.length} stays',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Stat(
                  label: 'Completed stays',
                  value: '${stays.length}',
                  sub: 'since this session began',
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Panel(
              radius: 24,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        'Recent stays',
                        style: Tx.h3.copyWith(color: c.chalk),
                      ),
                    ),
                    _Legend(color: c.sign, text: 'Slot 1'),
                    const SizedBox(width: 12),
                    _Legend(color: c.paint, text: 'Slot 2'),
                  ]),
                  const SizedBox(height: 18),
                  if (recent.isEmpty)
                    SizedBox(
                      height: 120,
                      child: Center(
                        child: Text(
                          'No stays yet. They appear here once a vehicle leaves a slot.',
                          textAlign: TextAlign.center,
                          style: Tx.small.copyWith(color: c.dim),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 168,
                      child: _Bars(
                        stays: recent,
                        colorFor: (id) => _slotColor(context, id),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Panel(
              radius: 24,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest changes',
                    style: Tx.h3.copyWith(color: c.chalk),
                  ),
                  const SizedBox(height: 10),
                  if (parkify.events.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'Waiting for the next change in a slot.',
                        style: Tx.small.copyWith(color: c.dim),
                      ),
                    )
                  else
                    for (final e in parkify.events.take(8))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: e.occupied ? c.busy : c.free,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Slot ${e.slot} ${e.occupied ? 'occupied' : 'freed'}',
                              style: Tx.body.copyWith(color: c.chalk),
                            ),
                          ),
                          TickBuilder(
                            builder: (_) => Text(
                              ago(e.at),
                              style: Tx.small.copyWith(color: c.mute),
                            ),
                          ),
                        ]),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.sub,
    this.small = false,
  });
  final String label;
  final String value;
  final String sub;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Panel(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Tx.small.copyWith(color: c.dim, fontSize: 12.5),
            ),
            const Spacer(),
            Text(
              value,
              style: Tx.h2.copyWith(
                fontSize: small ? 17 : 26,
                color: small ? c.dim : c.chalk,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: Tx.small.copyWith(color: c.mute, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(text, style: Tx.small.copyWith(color: c.dim)),
    ]);
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.stays, required this.colorFor});
  final List<Stay> stays;
  final Color Function(int slot) colorFor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxS = stays.map((s) => s.duration.inSeconds).reduce(math.max);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < stays.length; i++)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: maxS == 0
                        ? 0.0
                        : stays[i].duration.inSeconds / maxS,
                  ),
                  duration: Duration(milliseconds: 550 + i * 60),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => Container(
                    width: 20,
                    height: 6 + 118 * v,
                    decoration: BoxDecoration(
                      color: colorFor(stays[i].slot),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: colorFor(stays[i].slot).o(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fmtShort(stays[i].duration),
                  style: Tx.small.copyWith(fontSize: 11, color: c.dim),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
