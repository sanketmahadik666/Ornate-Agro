import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/data/database/app_database_impl.dart';

/// App initialization: DB, auth state, sync.
/// Called once before runApp.
Future<AppDatabaseImpl> bootstrap() async {
  // Initialize secure storage
  const secureStorage = FlutterSecureStorage();
  
  // Initialize local database
  final database = AppDatabaseImpl();
  await database.init();
  
  // TODO: Initialize sync engine
  // TODO: Check for pending sync operations
  
  return database;
}
