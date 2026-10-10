import 'package:flutter/material.dart';
import 'theme/kino_theme.dart';
import 'ui/home_screen.dart';

final settings = AppSettings();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        builder: (_, __) => MaterialApp(
          title: 'Kino Oracle',
          debugShowCheckedModeBanner: false,
          theme: settings.spec.materialTheme,
          home: const HomeScreen(),
        ),
      );
}
