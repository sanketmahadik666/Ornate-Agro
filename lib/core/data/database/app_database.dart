// Req 10: Local DB (encrypted), offline persistence.
// TODO: sqflite + flutter_secure_storage for encryption key.
// Tables: farmers, distributions, yield_returns, contact_logs, crop_types, users, sync_queue

abstract class AppDatabase {
  Future<void> init();
  // Farmer CRUD, distribution CRUD, etc. — add as needed
}
