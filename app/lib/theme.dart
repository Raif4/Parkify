import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Semantic palette tokens supporting both Midnight Sapphire (dark)
/// and Executive Ivory (light) modes.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.asphalt,
    required this.panel,
    required this.panelHi,
    required this.deep,
    required this.line,
    required this.chalk,
    required this.dim,
    required this.mute,
    required this.sign,
    required this.signSoft,
    required this.paint,
    required this.free,
    required this.busy,
    required this.shadow,
    required this.cardGradient,
    required this.isDark,
  });

  final Color asphalt;
  final Color panel;
  final Color panelHi;
  final Color deep;
  final Color line;
  final Color chalk;
  final Color dim;
  final Color mute;
  final Color sign;
  final Color signSoft;
  final Color paint;
  final Color free;
  final Color busy;
  final Color shadow;
  final List<Color> cardGradient;
  final bool isDark;

  static const dark = AppColors(
    asphalt: Color(0xFF0A0F1D), // midnight deep navy
    panel: Color(0xFF111C2E),   // elevated sapphire panel
    panelHi: Color(0xFF17243B), // raised card surface
    deep: Color(0xFF0D1424),    // recessed wells / bay map ground
    line: Color(0xFF1E2E4A),    // frosted sapphire border
    chalk: Color(0xFFF8FAFC),   // crisp high-contrast text
    dim: Color(0xFF94A3B8),     // secondary slate
    mute: Color(0xFF64748B),    // muted label / hint
    sign: Color(0xFF2563EB),    // electric royal sapphire
    signSoft: Color(0xFF60A5FA),// soft sapphire text/pill
    paint: Color(0xFFF59E0B),   // champagne amber signature
    free: Color(0xFF10B981),    // emerald mint
    busy: Color(0xFFF43F5E),    // ruby crimson
    shadow: Color(0x66000000),  // ambient shadow
    cardGradient: [Color(0xFF121D30), Color(0xFF0F1829)],
    isDark: true,
  );

  static const light = AppColors(
    asphalt: Color(0xFFF8FAFC), // porcelain pearl background
    panel: Color(0xFFFFFFFF),   // pure white card
    panelHi: Color(0xFFF1F5F9), // light raised card surface
    deep: Color(0xFFE8EEF5),    // recessed wells / light bay ground
    line: Color(0xFFE2E8F0),    // hairline border
    chalk: Color(0xFF0F172A),   // deep midnight navy text
    dim: Color(0xFF475569),     // secondary slate text
    mute: Color(0xFF94A3B8),    // muted label / hint
    sign: Color(0xFF1D4ED8),    // rich royal blue
    signSoft: Color(0xFF2563EB),// soft royal blue
    paint: Color(0xFFD97706),   // satin amber signature
    free: Color(0xFF059669),    // deep emerald
    busy: Color(0xFFE11D48),    // deep ruby
    shadow: Color(0x120F172A),  // multi-layered soft drop shadow
    cardGradient: [Color(0xFFFFFFFF), Color(0xFFFAFCFF)],
    isDark: false,
  );

  @override
  AppColors copyWith({
    Color? asphalt,
    Color? panel,
    Color? panelHi,
    Color? deep,
    Color? line,
    Color? chalk,
    Color? dim,
    Color? mute,
    Color? sign,
    Color? signSoft,
    Color? paint,
    Color? free,
    Color? busy,
    Color? shadow,
    List<Color>? cardGradient,
    bool? isDark,
  }) {
    return AppColors(
      asphalt: asphalt ?? this.asphalt,
      panel: panel ?? this.panel,
      panelHi: panelHi ?? this.panelHi,
      deep: deep ?? this.deep,
      line: line ?? this.line,
      chalk: chalk ?? this.chalk,
      dim: dim ?? this.dim,
      mute: mute ?? this.mute,
      sign: sign ?? this.sign,
      signSoft: signSoft ?? this.signSoft,
      paint: paint ?? this.paint,
      free: free ?? this.free,
      busy: busy ?? this.busy,
      shadow: shadow ?? this.shadow,
      cardGradient: cardGradient ?? this.cardGradient,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      asphalt: Color.lerp(asphalt, other.asphalt, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelHi: Color.lerp(panelHi, other.panelHi, t)!,
      deep: Color.lerp(deep, other.deep, t)!,
      line: Color.lerp(line, other.line, t)!,
      chalk: Color.lerp(chalk, other.chalk, t)!,
      dim: Color.lerp(dim, other.dim, t)!,
      mute: Color.lerp(mute, other.mute, t)!,
      sign: Color.lerp(sign, other.sign, t)!,
      signSoft: Color.lerp(signSoft, other.signSoft, t)!,
      paint: Color.lerp(paint, other.paint, t)!,
      free: Color.lerp(free, other.free, t)!,
      busy: Color.lerp(busy, other.busy, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      cardGradient: [
        Color.lerp(cardGradient.first, other.cardGradient.first, t)!,
        Color.lerp(cardGradient.last, other.cardGradient.last, t)!,
      ],
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// Dynamic access to theme palette and dark fallbacks.
class PK {
  PK._();

  // Static constants (Midnight Sapphire defaults)
  static const asphalt = Color(0xFF0A0F1D);
  static const panel = Color(0xFF111C2E);
  static const panelHi = Color(0xFF17243B);
  static const deep = Color(0xFF0D1424);
  static const line = Color(0xFF1E2E4A);
  static const chalk = Color(0xFFF8FAFC);
  static const dim = Color(0xFF94A3B8);
  static const mute = Color(0xFF64748B);
  static const sign = Color(0xFF2563EB);
  static const signSoft = Color(0xFF60A5FA);
  static const paint = Color(0xFFF59E0B);
  static const free = Color(0xFF10B981);
  static const busy = Color(0xFFF43F5E);

  /// Access dynamic semantic colors matching current theme mode.
  static AppColors of(BuildContext context) {
    final ext = Theme.of(context).extension<AppColors>();
    if (ext != null) return ext;
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
  }
}

extension BuildContextThemeX on BuildContext {
  AppColors get colors => PK.of(this);
}

extension ColorX on Color {
  /// Opacity helper that avoids deprecated withOpacity.
  Color o(double v) => withAlpha((v * 255).round().clamp(0, 255).toInt());
}

/// Theme mode preference selector.
enum AppThemePreference { system, light, dark }

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get themeMode => _mode;

  AppThemePreference get preference {
    switch (_mode) {
      case ThemeMode.light:
        return AppThemePreference.light;
      case ThemeMode.dark:
        return AppThemePreference.dark;
      case ThemeMode.system:
        return AppThemePreference.system;
    }
  }

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final pref = p.getString('theme_mode') ?? 'system';
    if (pref == 'light') {
      _mode = ThemeMode.light;
    } else if (pref == 'dark') {
      _mode = ThemeMode.dark;
    } else {
      _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setPreference(AppThemePreference pref) async {
    switch (pref) {
      case AppThemePreference.light:
        _mode = ThemeMode.light;
        break;
      case AppThemePreference.dark:
        _mode = ThemeMode.dark;
        break;
      case AppThemePreference.system:
        _mode = ThemeMode.system;
        break;
    }
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString('theme_mode', pref.name);
  }
}

final ThemeController themeController = ThemeController();

/// Type scale using the Overpass family.
class Tx {
  Tx._();
  static const _f = 'Overpass';

  static const display = TextStyle(
    fontFamily: _f,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.08,
    letterSpacing: -0.9,
    color: PK.chalk,
  );
  static const h2 = TextStyle(
    fontFamily: _f,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.35,
    color: PK.chalk,
  );
  static const h3 = TextStyle(
    fontFamily: _f,
    fontSize: 16.5,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.2,
    color: PK.chalk,
  );
  static const body = TextStyle(
    fontFamily: _f,
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: -0.15,
    color: PK.dim,
  );
  static const small = TextStyle(
    fontFamily: _f,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: -0.1,
    color: PK.dim,
  );
  static const overline = TextStyle(
    fontFamily: _f,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 1.1,
    color: PK.mute,
  );
  static const big = TextStyle(
    fontFamily: _f,
    fontSize: 62,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -2.2,
    color: PK.chalk,
  );
}

ThemeData buildDarkTheme() {
  const c = AppColors.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Overpass',
    scaffoldBackgroundColor: c.asphalt,
    cardColor: c.panel,
    colorScheme: ColorScheme.dark(
      primary: c.sign,
      surface: c.panel,
      onSurface: c.chalk,
      outline: c.line,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    extensions: const [c],
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.paint,
      selectionHandleColor: c.paint,
      selectionColor: c.sign.o(0.35),
    ),
  );
}

ThemeData buildLightTheme() {
  const c = AppColors.light;
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Overpass',
    scaffoldBackgroundColor: c.asphalt,
    cardColor: c.panel,
    colorScheme: ColorScheme.light(
      primary: c.sign,
      surface: c.panel,
      onSurface: c.chalk,
      outline: c.line,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    extensions: const [c],
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.paint,
      selectionHandleColor: c.paint,
      selectionColor: c.sign.o(0.25),
    ),
  );
}

String fmtDur(Duration d) {
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  if (s < 60) return '${s}s';
  if (s < 3600) return '${s ~/ 60}m ${(s % 60).toString().padLeft(2, '0')}s';
  return '${s ~/ 3600}h ${((s % 3600) ~/ 60).toString().padLeft(2, '0')}m';
}

String fmtShort(Duration d) {
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  if (s < 60) return '${s}s';
  if (s < 3600) return '${s ~/ 60}m';
  return '${s ~/ 3600}h${((s % 3600) ~/ 60)}m';
}

String ago(DateTime t) {
  final s = DateTime.now().difference(t).inSeconds;
  if (s < 5) return 'just now';
  if (s < 60) return '${s}s ago';
  if (s < 3600) return '${s ~/ 60}m ago';
  return '${s ~/ 3600}h ago';
}

/// Page transition: subtle rise and fade.
Route<T> smoothRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 460),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, anim, _, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}
