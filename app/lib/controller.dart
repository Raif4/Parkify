import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

const gatewayUrl = 'http://192.168.1.50/status';

/// Single source of truth for the UI. Talks to two ESP8266 discs
/// (one per slot) or runs a built-in demo.
class ParkifyController extends ChangeNotifier {
  bool useMock = false;
  String ip1 = '';
  String ip2 = '';
  bool loading = true;
  DateTime? lastUpdate;
  bool showDock = true;

  List<SlotInfo> slots = [
    const SlotInfo(id: 1, zone: 'Zone A', place: 'Entrance'),
    const SlotInfo(id: 2, zone: 'Zone B', place: 'Basement'),
  ];
  final List<Stay> stays = [];
  final List<SlotEvent> events = [];
  final List<bool> notify = [false, false];

  /// Called when a slot with notify=true goes occupied -> free.
  void Function(SlotInfo slot)? onFreedAlert;

  final math.Random _rng = math.Random();
  final http.Client _client = http.Client();
  int _gatewayFailures = 0;
  final List<DateTime> _next = [DateTime.now(), DateTime.now()];
  Timer? _timer;
  Timer? _gatewayTimer;
  Timer? _loadTimer;
  bool _busy = false;

  String ipFor(int i) => i == 0 ? ip1 : ip2;

  int get freeCount => slots.where((s) => s.occupied == false).length;
  int get busyCount => slots.where((s) => s.occupied == true).length;

  LinkState get overallLink {
    if (slots.any((s) => s.link == LinkState.live)) return LinkState.live;
    if (slots.every((s) => s.link == LinkState.lost)) return LinkState.lost;
    return LinkState.connecting;
  }

  /// Shown only after at least two completed occupied -> free stays.
  Duration? get avgStay {
    if (stays.length < 2) return null;
    final total = stays.fold<int>(0, (a, s) => a + s.duration.inSeconds);
    return Duration(seconds: (total / stays.length).round());
  }

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    useMock = p.getBool('mock') ?? true;
    ip1 = p.getString('ip1') ?? '';
    ip2 = p.getString('ip2') ?? '';
    showDock = p.getBool('dock') ?? true;
    _start();
  }

  Future<void> configure(
      {required bool mock, required String a, required String b}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('mock', mock);
    await p.setString('ip1', a);
    await p.setString('ip2', b);
    useMock = mock;
    ip1 = a;
    ip2 = b;
    _start();
  }

  void toggleNotify(int i) {
    notify[i] = !notify[i];
    notifyListeners();
  }

  Future<void> setShowDock(bool v) async {
    showDock = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool('dock', v);
  }

  /// Asks the puck for slot [i] to recalibrate. Returns true if it answered.
  Future<bool> recalibrateSlot(int i) async {
    try {
      final res = await _client
          .get(Uri.parse('http://192.168.1.50/recalibrate?slot=${i + 1}'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return false;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return j['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  void _start() {
    _timer?.cancel();
    _gatewayTimer?.cancel();
    _loadTimer?.cancel();
    loading = true;
    lastUpdate = null;
    stays.clear();
    events.clear();
    notify[0] = false;
    notify[1] = false;
    _gatewayFailures = 0;
    slots = [
      for (final s in slots) SlotInfo(id: s.id, zone: s.zone, place: s.place)
    ];
    notifyListeners();

    if (useMock) {
      _loadTimer = Timer(const Duration(milliseconds: 1400), () {
        _seedMock();
        loading = false;
        notifyListeners();
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _mockTick());
      _pollOnce();
      _gatewayTimer =
          Timer.periodic(const Duration(milliseconds: 500), (_) => _pollOnce());
    } else {
      _loadTimer = Timer(const Duration(milliseconds: 2500), () {
        if (loading) {
          loading = false;
          notifyListeners();
        }
      });
      _pollOnce();
      _timer =
          Timer.periodic(const Duration(milliseconds: 500), (_) => _pollOnce());
    }
  }

  // ---------- demo data ----------

  void _seedMock() {
    final now = DateTime.now();
    slots = [
      slots[0].copyWith(
          occupied: true,
          since: now.subtract(const Duration(seconds: 37))),
      slots[1].copyWith(
          occupied: false,
          since: now.subtract(const Duration(minutes: 4))),
    ];
    for (final m in [22, 41, 9, 55, 31]) {
      stays.add(Stay(1, Duration(minutes: m), now.subtract(Duration(minutes: 60 + m))));
    }
    for (final m in [14, 38, 26]) {
      stays.add(Stay(2, Duration(minutes: m), now.subtract(Duration(minutes: 30 + m))));
    }
    _next[0] = now.add(Duration(seconds: 20 + _rng.nextInt(10)));
    _next[1] = now.add(Duration(seconds: 35 + _rng.nextInt(15)));
  }

  void _mockTick() {
    if (loading) return;
    final now = DateTime.now();
    lastUpdate = now;
    for (var i = 0; i < 2; i++) {
      if (now.isAfter(_next[i])) {
        final occ = !(slots[i].occupied ?? false);
        _apply(i, occ, now);
        _next[i] = now.add(Duration(seconds: 45 + _rng.nextInt(76)));
      }
    }
  }

  /// Developer helper (demo mode only): flip a slot right now.
  void simulateToggle(int i) {
    if (!useMock || loading) return;
    final now = DateTime.now();
    _apply(i, !(slots[i].occupied ?? false), now);
    _next[i] = now.add(Duration(seconds: 45 + _rng.nextInt(76)));
  }

  // ---------- live ESP polling ----------

  Future<void> _pollOnce() async {
    if (_busy) return;
    _busy = true;
    try {
      await _pollGateway();
    } finally {
      _busy = false;
    }
  }

  Future<void> _pollGateway() async {
    try {
      final res = await _client
          .get(Uri.parse(gatewayUrl))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) throw Exception('bad status');
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final slotData = j['slots'] as List<dynamic>;
      final now = DateTime.now();
      final taken = [
        for (var i = 0; i < 2; i++)
          (slotData[i] as Map<String, dynamic>)['taken'] as bool,
      ];
      _gatewayFailures = 0;
      for (var i = 0; i < 2; i++) {
        if (useMock) {
          if (slots[i].link != LinkState.live) {
            slots[i] = slots[i].copyWith(link: LinkState.live);
            notifyListeners();
          }
        } else {
          _apply(i, taken[i], now);
        }
      }
    } catch (_) {
      _gatewayFailures++;
      if (_gatewayFailures >= 5) {
        _markLost(0);
        _markLost(1);
      }
    }
  }

  void _markLost(int i) {
    if (slots[i].link != LinkState.lost) {
      slots[i] = slots[i].copyWith(link: LinkState.lost);
      notifyListeners();
    }
  }

  // ---------- shared state update ----------

  void _apply(int i, bool occ, DateTime since, {double? delta}) {
    final s = slots[i];
    final now = DateTime.now();
    final changed = s.occupied != null && s.occupied != occ;

    var useSince = since;
    if (!changed &&
        s.since != null &&
        since.difference(s.since!).abs() < const Duration(seconds: 3)) {
      useSince = s.since!; // avoid jitter from network latency
    }

    if (changed) {
      events.insert(0, SlotEvent(s.id, occ, now));
      if (events.length > 30) events.removeLast();
      if (!occ) {
        stays.add(Stay(s.id, now.difference(s.since ?? now), now));
        if (stays.length > 60) stays.removeAt(0);
      }
    }

    slots[i] = s.copyWith(
        occupied: occ,
        since: useSince,
        link: useMock ? s.link : LinkState.live,
        deltaUt: delta);
    lastUpdate = now;
    if (loading && !useMock) loading = false;

    if (changed && !occ && notify[i]) {
      notify[i] = false;
      onFreedAlert?.call(slots[i]);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gatewayTimer?.cancel();
    _loadTimer?.cancel();
    _client.close();
    super.dispose();
  }
}

final ParkifyController parkify = ParkifyController();
