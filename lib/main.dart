import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/kino_look.dart';
import 'theme/kino_theme.dart';
import 'ui/home_screen.dart';

final settings = AppSettings();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge esplicito: gli insets li gestiamo noi nel builder del MaterialApp.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await settings.load();
  runApp(const KinoApp());
}

class KinoApp extends StatefulWidget {
  const KinoApp({super.key});
  @override
  State<KinoApp> createState() => _KinoAppState();
}

class _KinoAppState extends State<KinoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Segue il tema del sistema quando l'aspetto e "Sistema".
  @override
  void didChangePlatformBrightness() {
    if (settings.appearance == Appearance.system) setState(() {});
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: settings,
        builder: (_, __) {
          final spec = settings.spec;
          final theme = spec.theme;
          final darkBg = theme.brightness == Brightness.dark;
          final iconBrightness = darkBg ? Brightness.light : Brightness.dark;
          return MaterialApp(
            title: 'Kino Oracle',
            debugShowCheckedModeBanner: false,
            theme: theme,
            // Tiene i contenuti sopra i 3 pulsanti / la barra gesti di Android (Samsung incluso)
            // e colora la barra di sistema come lo sfondo del tema.
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                systemNavigationBarColor: spec.bg,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarIconBrightness: iconBrightness,
                systemNavigationBarContrastEnforced: false,
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: iconBrightness,
              ),
              child: ColoredBox(
                color: spec.bg,
                child: SafeArea(
                  top: false, // la AppBar gestisce gia la status bar
                  left: false,
                  right: false,
                  child: child!,
                ),
              ),
            ),
            home: const HomeScreen(),
          );
        },
      );
}
