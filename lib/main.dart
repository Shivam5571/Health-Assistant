import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// Required for Notification Scheduling
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'frontend/screens/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Timezone Database
  // This is required for flutter_local_notifications to schedule alarms
  tz.initializeTimeZones();

  runApp(const HealthFlyApp());
}

class HealthFlyApp extends StatelessWidget {
  const HealthFlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const SplashScreen(),
    );
  }
}