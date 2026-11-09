import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';
import 'widgets.dart';

enum LotStatus { live, soon }

/// A parking lot listed in the app.
/// Only lots with status [LotStatus.live] show real sensor data.
class Lot {
  const Lot({
    required this.id,
    required this.name,
    required this.city,
    required this.type,
    required this.initials,
    required this.color,
    required this.status,
    required this.mapsQuery,
    this.address,
    this.hours,
  });

  final String id; // also the text inside the lot's QR code
  final String name;
  final String city;
  final String type;
  final String initials;
  final Color color;
  final LotStatus status;
  final String mapsQuery;

  /// Optional. Shown on the lot screen only when set.
  final String? address;
  final String? hours;
}

/// The pilot lot: backed by the 2-slot prototype.
const Lot kNexus = Lot(
  id: 'nexus-mall',
  name: 'Nexus Mall',
  city: 'Mangaluru',
  type: 'Mall',
  initials: 'N',
  color: PK.sign,
  status: LotStatus.live,
  mapsQuery: 'Nexus Mall Mangaluru',
);

const List<Lot> kLots = [
  kNexus,
  Lot(
    id: 'city-centre-mall',
    name: 'City Centre Mall',
    city: 'Mangaluru',
    type: 'Mall',
    initials: 'CC',
    color: Color(0xFFF59E0B),
    status: LotStatus.soon,
    mapsQuery: 'City Centre Mall Mangaluru',
  ),
  Lot(
    id: 'empire-mall',
    name: 'Empire Mall',
    city: 'Mangaluru',
    type: 'Mall',
    initials: 'E',
    color: Color(0xFF38BDF8),
    status: LotStatus.soon,
    mapsQuery: 'Empire Mall Mangaluru',
  ),
  Lot(
    id: 'big-bazaar',
    name: 'Big Bazaar',
    city: 'Mangaluru',
    type: 'Retail',
    initials: 'BB',
    color: Color(0xFFFB923C),
    status: LotStatus.soon,
    mapsQuery: 'Big Bazaar Mangaluru',
  ),
  Lot(
    id: 'reliance-smart-point',
    name: 'Reliance Smart Point',
    city: 'Mangaluru',
    type: 'Retail',
    initials: 'RS',
    color: Color(0xFFA78BFA),
    status: LotStatus.soon,
    mapsQuery: 'Reliance Smart Point Mangaluru',
  ),
];

/// Opens the lot in Google Maps (or the browser if Maps is not installed).
Future<void> openInMaps(Lot lot) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(lot.mapsQuery)}',
  );
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) throw Exception('no handler');
  } catch (_) {
    Toast.show(
      navKey,
      title: 'Could not open Maps',
      body: 'No app on this device could open the link.',
      color: PK.paint,
      icon: Icons.info_outline_rounded,
    );
  }
}

/// Bottom sheet shown when a lot that is not live yet is tapped.
void showSoonSheet(BuildContext context, Lot lot) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.o(0.55),
    builder: (ctx) {
      final c = ctx.colors;
      return Container(
        padding: EdgeInsets.fromLTRB(
          22,
          14,
          22,
          26 + MediaQuery.of(ctx).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: c.panel,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: c.line, width: 1.2)),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: c.line,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              MonoTile(initials: lot.initials, color: lot.color, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lot.name,
                      style: Tx.h2.copyWith(color: c.chalk),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${lot.type}, ${lot.city}',
                      style: Tx.small.copyWith(color: c.dim),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Text(
              'Parkify is not live at ${lot.name} yet. ${kNexus.name} is the pilot lot.',
              style: Tx.body.copyWith(color: c.dim),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: PkButton(
                  label: 'Open in Maps',
                  icon: Icons.near_me_rounded,
                  onTap: () => openInMaps(lot),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PkButton(
                  label: 'Got it',
                  filled: true,
                  onTap: () => Navigator.of(ctx).pop(),
                ),
              ),
            ]),
          ],
        ),
      );
    },
  );
}
