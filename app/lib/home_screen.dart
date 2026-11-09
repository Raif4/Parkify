import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller.dart';
import 'dev_dock.dart';
import 'lot_screen.dart';
import 'lots.dart';
import 'models.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      devDockReady.value = true;
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool _match(Lot l) {
    final q = _text.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return '${l.name} ${l.city} ${l.type}'.toLowerCase().contains(q);
  }

  Widget _search(AppColors c) {
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: focused ? c.sign : c.line,
          width: focused ? 1.8 : 1.2,
        ),
        boxShadow: focused
            ? [BoxShadow(color: c.sign.o(0.2), blurRadius: 20, spreadRadius: -2)]
            : [
                BoxShadow(
                  color: c.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Row(children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.search_rounded,
            key: ValueKey(focused),
            color: focused ? c.chalk : c.mute,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _text,
            focusNode: _focus,
            onChanged: (_) => setState(() {}),
            cursorColor: c.paint,
            style: Tx.h3.copyWith(fontWeight: FontWeight.w500, color: c.chalk),
            decoration: InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              hintText: 'Search a mall or parking lot',
              hintStyle: Tx.body.copyWith(color: c.mute),
            ),
          ),
        ),
        if (_text.text.isNotEmpty)
          Pressable(
            scale: 0.85,
            onTap: () => setState(_text.clear),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, color: c.dim, size: 20),
            ),
          ),
      ]),
    );
  }

  Widget _lots(BuildContext context) {
    final c = context.colors;
    final live =
        kLots.where((l) => l.status == LotStatus.live && _match(l)).toList();
    final soon =
        kLots.where((l) => l.status == LotStatus.soon && _match(l)).toList();

    Widget body;
    if (parkify.loading) {
      body = const _HomeSkeleton(key: ValueKey('skeleton'));
    } else if (live.isEmpty && soon.isEmpty) {
      body = const _NoMatch(key: ValueKey('none'));
    } else {
      body = Column(
        key: const ValueKey('lots'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (live.isNotEmpty) ...[
            Text('Live now', style: Tx.h2.copyWith(color: c.chalk)),
            const SizedBox(height: 14),
            for (final l in live) _LotCard(lot: l),
          ],
          if (live.isNotEmpty && soon.isNotEmpty) const SizedBox(height: 32),
          if (soon.isNotEmpty) ...[
            Row(children: [
              Text('Coming soon', style: Tx.h2.copyWith(color: c.chalk)),
              const Spacer(),
              Text(
                soon.length == 1 ? '1 lot' : '${soon.length} lots',
                style: Tx.small.copyWith(color: c.mute),
              ),
            ]),
            const SizedBox(height: 6),
            for (var i = 0; i < soon.length; i++) ...[
              _SoonRow(lot: soon[i]),
              if (i < soon.length - 1) const _RowDivider(),
            ],
          ],
        ],
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      child: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.asphalt,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
            children: [
              Reveal(
                index: 0,
                child: Row(children: [
                  // Long-press the sign for quick developer options.
                  GestureDetector(
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      Navigator.of(context)
                          .push(smoothRoute(const SettingsScreen()));
                    },
                    child: const SignTile(size: 42),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Parkify',
                      style: Tx.display.copyWith(color: c.chalk),
                    ),
                  ),
                  RoundButton(
                    icon: Icons.tune_rounded,
                    onTap: () => Navigator.of(context)
                        .push(smoothRoute(const SettingsScreen())),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              Reveal(
                index: 1,
                child: Text(
                  'Find parking before you arrive.',
                  style: Tx.body.copyWith(color: c.dim),
                ),
              ),
              const SizedBox(height: 24),
              Reveal(index: 2, child: _search(c)),
              const SizedBox(height: 14),
              const Reveal(index: 3, child: _ScanButton()),
              const SizedBox(height: 32),
              Reveal(
                index: 4,
                child: ListenableBuilder(
                  listenable: parkify,
                  builder: (context, _) => _lots(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      scale: 0.97,
      onTap: () =>
          Navigator.of(context).push(smoothRoute(const ScannerScreen())),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              c.sign,
              Color.lerp(c.sign, const Color(0xFF1E3A8A), 0.25)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: c.sign.o(0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(children: [
          Positioned(
            left: 22,
            right: 22,
            bottom: 9,
            height: 3,
            child: DashedLine(
              color: c.paint,
              dash: 12,
              gap: 9,
              stroke: 2.5,
            ),
          ),
          const Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Scan lot QR',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: Colors.white,
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _LotCard extends StatelessWidget {
  const _LotCard({required this.lot});
  final Lot lot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final free = parkify.freeCount;
    final n = parkify.slots.length;
    return Pressable(
      scale: 0.97,
      onTap: () =>
          Navigator.of(context).push(smoothRoute(LotScreen(lot: lot))),
      child: Panel(
        radius: 26,
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Row(children: [
            MonoTile(initials: lot.initials, color: lot.color, size: 54),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lot.name, style: Tx.h2.copyWith(color: c.chalk)),
                  const SizedBox(height: 2),
                  Text(
                    '${lot.type}, ${lot.city}',
                    style: Tx.small.copyWith(color: c.dim),
                  ),
                ],
              ),
            ),
            LivePill(link: parkify.overallLink, demo: parkify.useMock),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            for (final s in parkify.slots) _BayGlyph(slot: s),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$free of $n slots free',
                style: Tx.h3.copyWith(
                  color: free == 0 ? c.busy : c.chalk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: c.dim, size: 15),
          ]),
        ]),
      ),
    );
  }
}

class _SoonRow extends StatelessWidget {
  const _SoonRow({required this.lot});
  final Lot lot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      scale: 0.98,
      onTap: () => showSoonSheet(context, lot),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          MonoTile(
            initials: lot.initials,
            color: lot.color,
            size: 48,
            muted: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lot.name, style: Tx.h3.copyWith(color: c.chalk)),
                const SizedBox(height: 2),
                Text(
                  '${lot.type}, ${lot.city}',
                  style: Tx.small.copyWith(color: c.dim),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
            decoration: BoxDecoration(
              color: c.panelHi,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.line, width: 1.2),
            ),
            child: Text(
              'Soon',
              style: Tx.small.copyWith(
                color: c.mute,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 1.2,
      margin: const EdgeInsets.only(left: 62),
      color: c.line,
    );
  }
}

class _BayGlyph extends StatelessWidget {
  const _BayGlyph({required this.slot});
  final SlotInfo slot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final occ = slot.occupied == true;
    final unknown = slot.occupied == null;
    final color = unknown ? c.mute : (occ ? c.busy : c.free);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      width: 22,
      height: 32,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: occ ? color : color.o(c.isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(h: 134, r: 26),
            SizedBox(height: 32),
            Skeleton(h: 24, w: 140, r: 8),
            SizedBox(height: 18),
            Skeleton(h: 52, r: 18),
            SizedBox(height: 14),
            Skeleton(h: 52, r: 18),
            SizedBox(height: 14),
            Skeleton(h: 52, r: 18),
          ],
        ),
      );
}

class _NoMatch extends StatelessWidget {
  const _NoMatch({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Panel(
      padding: const EdgeInsets.all(26),
      child: SizedBox(
        width: double.infinity,
        child: Column(children: [
          Icon(Icons.search_off_rounded, color: c.mute, size: 34),
          const SizedBox(height: 12),
          Text(
            'No lots match that search',
            style: Tx.h3.copyWith(color: c.chalk),
          ),
          const SizedBox(height: 4),
          Text(
            'Try the mall name, or scan the QR at the entrance.',
            textAlign: TextAlign.center,
            style: Tx.small.copyWith(color: c.dim),
          ),
        ]),
      ),
    );
  }
}
