import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller.dart';
import 'dev_dock.dart';
import 'notifier.dart';
import 'splash_screen.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  parkify.onFreedAlert = (slot) {
    final title = 'Slot ${slot.id} is free';
    final body = '${slot.zone}, ${slot.place} just opened up';
    Toast.show(navKey, title: title, body: body);
    Notifier.show(title, body);
  };
  await Notifier.init();
  await themeController.init();
  await parkify.init();
  runApp(const ParkifyApp());
}

class ParkifyApp extends StatelessWidget {
  const ParkifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navKey,
          title: 'Parkify',
          debugShowCheckedModeBanner: false,
          themeMode: themeController.themeMode,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          builder: (context, child) => Stack(
            fit: StackFit.expand,
            children: [child ?? const SizedBox.shrink(), const DevDock()],
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
