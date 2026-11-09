import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller.dart';
import 'theme.dart';
import 'widgets.dart';

enum _Save { idle, saving, done }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _mock = parkify.useMock;
  late final TextEditingController _a =
      TextEditingController(text: parkify.ip1);
  late final TextEditingController _b =
      TextEditingController(text: parkify.ip2);
  _Save _save = _Save.idle;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (_save == _Save.saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _save = _Save.saving);
    await parkify.configure(mock: _mock, a: _a.text.trim(), b: _b.text.trim());
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _save = _Save.done);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _save = _Save.idle);
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
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
            children: [
              Row(children: [
                RoundButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 14),
                Text('Settings', style: Tx.h2.copyWith(color: c.chalk)),
              ]),
              const SizedBox(height: 24),

              // ---------------- APPEARANCE ----------------
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text('APPEARANCE', style: Tx.overline.copyWith(color: c.mute)),
              ),
              Panel(
                radius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Theme', style: Tx.h3.copyWith(color: c.chalk)),
                    const SizedBox(height: 3),
                    Text(
                      'Choose Light, Dark, or System visual style.',
                      style: Tx.small.copyWith(color: c.dim),
                    ),
                    const SizedBox(height: 16),
                    const _ThemeSelector(),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ---------------- DEVELOPER & HARDWARE ----------------
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text('HARDWARE & DEVELOPER',
                    style: Tx.overline.copyWith(color: c.mute)),
              ),
              Panel(
                radius: 22,
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Demo mode', style: Tx.h3.copyWith(color: c.chalk)),
                        const SizedBox(height: 3),
                        Text(
                          'Simulated slots, no physical hardware needed.',
                          style: Tx.small.copyWith(color: c.dim),
                        ),
                      ],
                    ),
                  ),
                  PkSwitch(
                    value: _mock,
                    onIcon: Icons.science_rounded,
                    offIcon: Icons.sensors_rounded,
                    onChanged: (v) => setState(() => _mock = v),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _mock ? 0.45 : 1.0,
                child: Panel(
                  radius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sensor addresses',
                          style: Tx.h3.copyWith(color: c.chalk)),
                      const SizedBox(height: 3),
                      Text(
                        'IP addresses output in the serial monitor (e.g. 192.168.43.20).',
                        style: Tx.small.copyWith(color: c.dim),
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Slot 1 address',
                        controller: _a,
                        enabled: !_mock,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        label: 'Slot 2 address',
                        controller: _b,
                        enabled: !_mock,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ListenableBuilder(
                listenable: parkify,
                builder: (context, _) => Panel(
                  radius: 22,
                  child: Column(children: [
                    for (final s in parkify.slots)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Expanded(
                            child: Text(
                              'Slot ${s.id} Link',
                              style: Tx.h3.copyWith(color: c.chalk),
                            ),
                          ),
                          LivePill(link: s.link, demo: parkify.useMock),
                        ]),
                      ),
                  ]),
                ),
              ),
              ListenableBuilder(
                listenable: parkify,
                builder: (context, _) {
                  if (!parkify.useMock || parkify.loading) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Panel(
                      radius: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Simulate flip',
                              style: Tx.h3.copyWith(color: c.chalk)),
                          const SizedBox(height: 3),
                          Text(
                            'Toggle slot occupancy instantly for live rehearsals.',
                            style: Tx.small.copyWith(color: c.dim),
                          ),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(
                              child: PkButton(
                                label: 'Slot 1',
                                icon: Icons.swap_vert_rounded,
                                onTap: () => parkify.simulateToggle(0),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PkButton(
                                label: 'Slot 2',
                                icon: Icons.swap_vert_rounded,
                                onTap: () => parkify.simulateToggle(1),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  );
                },
              ),
              ListenableBuilder(
                listenable: parkify,
                builder: (context, _) => Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Panel(
                    radius: 22,
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Floating dev dock',
                                style: Tx.h3.copyWith(color: c.chalk)),
                            const SizedBox(height: 3),
                            Text(
                              'Side calibration tab available on all screens.',
                              style: Tx.small.copyWith(color: c.dim),
                            ),
                          ],
                        ),
                      ),
                      PkSwitch(
                        value: parkify.showDock,
                        onIcon: Icons.build_rounded,
                        offIcon: Icons.visibility_off_rounded,
                        onChanged: (v) => parkify.setShowDock(v),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _SaveButton(state: _save, onTap: _apply),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Set the phone hotspot to 2.4 GHz. The ESP8266 cannot join 5 GHz networks.',
                  style: Tx.small.copyWith(color: c.mute),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final current = themeController.preference;
        return Row(children: [
          Expanded(
            child: _ThemeOption(
              label: 'System',
              icon: Icons.brightness_auto_rounded,
              selected: current == AppThemePreference.system,
              onTap: () =>
                  themeController.setPreference(AppThemePreference.system),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ThemeOption(
              label: 'Light',
              icon: Icons.light_mode_rounded,
              selected: current == AppThemePreference.light,
              onTap: () =>
                  themeController.setPreference(AppThemePreference.light),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ThemeOption(
              label: 'Dark',
              icon: Icons.dark_mode_rounded,
              selected: current == AppThemePreference.dark,
              onTap: () =>
                  themeController.setPreference(AppThemePreference.dark),
            ),
          ),
        ]);
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      scale: 0.94,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 64,
        decoration: BoxDecoration(
          color: selected ? c.sign.o(c.isDark ? 0.2 : 0.12) : c.panelHi,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? c.sign : c.line,
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? c.sign : c.dim,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Tx.small.copyWith(
                color: selected ? c.sign : c.dim,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatefulWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.enabled,
  });
  final String label;
  final TextEditingController controller;
  final bool enabled;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final f = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: c.deep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: f ? c.sign : c.line,
          width: f ? 1.8 : 1.2,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          widget.label,
          style: Tx.small.copyWith(
            color: f ? c.sign : c.dim,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          enabled: widget.enabled,
          keyboardType: TextInputType.url,
          cursorColor: c.paint,
          style: Tx.h3.copyWith(
            fontWeight: FontWeight.w500,
            color: c.chalk,
          ),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.only(top: 4),
            hintText: '192.168.43.20',
            hintStyle:
                Tx.h3.copyWith(color: c.mute, fontWeight: FontWeight.w400),
          ),
        ),
      ]),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.state, required this.onTap});
  final _Save state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final done = state == _Save.done;
    return Pressable(
      scale: 0.97,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        height: 60,
        decoration: BoxDecoration(
          color: done ? c.free : c.sign,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (done ? c.free : c.sign).o(0.35),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, a) => ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(a),
              child: FadeTransition(opacity: a, child: child),
            ),
            child: state == _Save.saving
                ? const BayLoader(
                    key: ValueKey('saving'),
                    size: 32,
                    color: Colors.white,
                  )
                : Row(
                    key: ValueKey(done),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        done ? Icons.check_rounded : Icons.link_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        done ? 'Saved' : 'Save and connect',
                        style: Tx.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
