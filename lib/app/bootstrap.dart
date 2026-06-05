import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/data/database/firebase_options.dart';

/// App initialization: Firebase and other core services.
/// Called once before runApp.
Future<void> bootstrap() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
}
