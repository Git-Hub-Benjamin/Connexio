import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'providers/sync_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize window manager for desktop platforms
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    
    // Get screen size and calculate default window size
    final screenSize = await windowManager.getSize();
    final defaultWidth = prefs.getDouble('windowWidth') ?? 200.0;
    final defaultHeight = prefs.getDouble('windowHeight') ?? 400.0;
    
    WindowOptions windowOptions = WindowOptions(
      size: Size(defaultWidth, defaultHeight),
      minimumSize: Size(150, 200),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: true,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProxyProvider<SettingsProvider, SyncProvider>(
          create: (_) => SyncProvider(),
          update: (_, settings, sync) => sync!..updateSettings(settings),
        ),
      ],
      child: const ConnexioApp(),
    ),
  );
}

class ConnexioApp extends StatelessWidget {
  const ConnexioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connexio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF03DAC6),
          surface: Color(0xFF1E1E2E),
          background: Color(0xFF11111B),
          error: Color(0xFFCF6679),
        ),
        scaffoldBackgroundColor: Color(0xFF11111B),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}
