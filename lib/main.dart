import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'main_screen.dart';
import 'sync_manager.dart';

// Global variable to hold and update the current language instantly
final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('en'));

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Define your FastAPI backend address here. 
  const String serverIp = '192.168.137.1'; 
  const int serverPort = 8000;

  // Start the background network listener
  SyncManager().initializeSyncListener(serverIp, serverPort); 
  
  runApp(const JJMCitizenApp());
}

class JJMCitizenApp extends StatelessWidget {
  const JJMCitizenApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder listens to appLocale and rebuilds the app when it changes
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, child) {
        return MaterialApp(
          title: 'JJM Citizen Feedback',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
          ),
          locale: locale, 
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('hi', ''), // Hindi
            Locale('mr', ''), // Marathi
          ],
          home: const MainScreen(),
        );
      },
    );
  }
}