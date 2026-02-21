import 'package:equatable/equatable.dart';

enum BacktestStatus { running, paused, completed, error, stopped }

/// Progress tracking entity (Req: Progress Tracking & Time Management)
class BacktestProgress extends Equatable {
  const BacktestProgress({
    required this.status,
    this.progressPercentage,
    this.elapsedSeconds = 0,
    this.backgroundSeconds = 0,
    this.activeSeconds = 0,
    this.estimatedRemainingSeconds,
    this.startTime,
  });

  final BacktestStatus status;
  final double? progressPercentage; // 0.0 to 100.0, null if indeterminate
  final int elapsedSeconds; // Total elapsed time
  final int backgroundSeconds; // Time while user was away
  final int activeSeconds; // Active processing time
  final int? estimatedRemainingSeconds; // ETA in seconds
  final DateTime? startTime;

  DateTime? get estimatedCompletionTime {
    if (estimatedRemainingSeconds == null || startTime == null) return null;
    return startTime!.add(Duration(seconds: elapsedSeconds + estimatedRemainingSeconds!));
  }

  String get formattedElapsedTime => _formatDuration(elapsedSeconds);
  String get formattedBackgroundTime => _formatDuration(backgroundSeconds);
  String get formattedActiveTime => _formatDuration(activeSeconds);
  String get formattedETA {
    if (estimatedRemainingSeconds == null) return 'Calculating...';
    return _formatDuration(estimatedRemainingSeconds!);
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${secs.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        status,
        progressPercentage,
        elapsedSeconds,
        backgroundSeconds,
        activeSeconds,
        estimatedRemainingSeconds,
      ];
}
