enum LinkState { connecting, live, lost }

class SlotInfo {
  const SlotInfo({
    required this.id,
    required this.zone,
    required this.place,
    this.occupied,
    this.since,
    this.link = LinkState.connecting,
    this.deltaUt,
  });

  final int id;
  final String zone;
  final String place;
  final bool? occupied; // null until the first reading arrives
  final DateTime? since; // when the current state began (phone clock)
  final LinkState link;
  final double? deltaUt;

  SlotInfo copyWith({
    bool? occupied,
    DateTime? since,
    LinkState? link,
    double? deltaUt,
  }) =>
      SlotInfo(
        id: id,
        zone: zone,
        place: place,
        occupied: occupied ?? this.occupied,
        since: since ?? this.since,
        link: link ?? this.link,
        deltaUt: deltaUt ?? this.deltaUt,
      );
}

/// A completed occupied -> free period.
class Stay {
  const Stay(this.slot, this.duration, this.endedAt);
  final int slot;
  final Duration duration;
  final DateTime endedAt;
}

class SlotEvent {
  const SlotEvent(this.slot, this.occupied, this.at);
  final int slot;
  final bool occupied;
  final DateTime at;
}
