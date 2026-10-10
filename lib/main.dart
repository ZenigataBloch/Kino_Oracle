import 'package:flutter/material.dart';
import 'theme/kino_theme.dart';
import 'ui/home_screen.dart';

final settings = AppSettings();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await settings.load();
  runApp(const KinoApp());
}

class KinoApp extends StatelessWidget {
  const KinoApp({super.key});
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
