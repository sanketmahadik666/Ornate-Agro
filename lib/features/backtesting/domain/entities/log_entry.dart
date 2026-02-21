import 'package:equatable/equatable.dart';

/// Log categories: Informational, Warning, Error (Req: Log Categorization)
enum LogCategory { informational, warning, error, debug }

/// Log entry entity for backtesting logs
class LogEntry extends Equatable {
  const LogEntry({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.message,
    this.details,
    this.metadata,
  });

  final String id;
  final DateTime timestamp;
  final LogCategory category;
  final String message;
  final String? details; // Expandable details for debug logs
  final Map<String, dynamic>? metadata; // Variable dumps, execution paths, etc.

  String get formattedTimestamp {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  bool get isDebug => category == LogCategory.debug;

  @override
  List<Object?> get props => [id, timestamp, category, message];
}
